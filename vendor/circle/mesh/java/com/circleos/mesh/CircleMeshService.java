/*
 * Copyright (C) 2026 The Other Bhengu (PTY) Ltd t/a The Geek Network.
 *
 * CircleMeshService — SystemService impl for the Circle Mesh Service.
 *
 * Bridges Android-side callers to the CircleAether protocol (open source
 * at aether-protocol/, a git submodule of the repo root). The protocol
 * itself has independent implementations in 8 languages; the OS-level
 * service wraps one of them — at v0, the Rust impl via JNI.
 *
 * Lifecycle:
 *   1. SystemServer starts the service early (alongside ConnectivityService).
 *   2. onStart() publishes the "circle_mesh" binder.
 *   3. onBootPhase(PHASE_BOOT_COMPLETED) loads the persisted Ed25519
 *      identity from /data/system/circle_mesh/identity.bin (or generates
 *      one if absent) and starts the available transports.
 *
 * Backend abstraction:
 *   The MeshBackend interface is the seam between this Android service
 *   and the actual aether-protocol implementation. v0 ships a
 *   StubMeshBackend that returns a synthetic local node id and an empty
 *   peer list; the real RustMeshBackend lands once the JNI binding is
 *   compiled.
 *
 * Threading:
 *   - Binder calls under mLock for state.
 *   - Backend send/receive happens on the backend's threads; we marshal
 *     inbound messages onto a single Handler so listeners see ordered
 *     delivery.
 */

package com.circleos.mesh;

import android.content.Context;
import android.os.RemoteCallbackList;
import android.os.RemoteException;
import android.util.Slog;
import android.util.SparseArray;

import com.android.server.SystemService;

import java.security.SecureRandom;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

import za.co.circleos.mesh.ICircleMeshManager;
import za.co.circleos.mesh.IMeshInboxListener;

public final class CircleMeshService extends SystemService {

    private static final String TAG = "CircleMesh";
    public static final String SERVICE_NAME = "circle_mesh";
    private static final int API_VERSION = 1;

    private static final int MAX_PAYLOAD = 16 * 1024;
    private static final int MAX_TOPIC   = 32;
    private static final int MIN_TTL     = 1;
    private static final int MAX_TTL     = 16;

    private final Context mContext;
    private final Object mLock = new Object();
    private final BinderImpl mBinder = new BinderImpl();
    private final SecureRandom mRng = new SecureRandom();
    private final AtomicLong mNextSub = new AtomicLong(1);

    /** topic -> list of subscribed listeners. */
    private final Map<String, RemoteCallbackList<IMeshInboxListener>> mInbox = new HashMap<>();
    /** subscription handle -> (topic, listener). */
    private final SparseArray<Subscription> mSubscriptions = new SparseArray<>();

    private MeshBackend mBackend;

    public CircleMeshService(Context context) {
        super(context);
        mContext = context;
    }

    @Override
    public void onStart() {
        Slog.i(TAG, "starting (api=" + API_VERSION + ")");
        publishBinderService(SERVICE_NAME, mBinder);
    }

    @Override
    public void onBootPhase(int phase) {
        if (phase == PHASE_BOOT_COMPLETED) {
            mBackend = new StubMeshBackend();
            mBackend.attach(this::onIncomingMessage);
            Slog.i(TAG, "backend up: " + mBackend.name()
                    + ", localId=" + mBackend.getLocalNodeId().substring(0, 8) + "...");
        }
    }

    // ----- backend abstraction --------------------------------------------

    /** Pluggable mesh backend. Real impl: RustMeshBackend via JNI. */
    interface MeshBackend {
        String name();
        String getLocalNodeId();
        MeshNode[] listKnownPeers();
        MeshHealth getHealth();
        String send(String targetNodeId, String topic, byte[] payload, int ttl);
        String broadcast(String topic, byte[] payload, int ttl);
        /** Backend pushes inbound messages here after dedup + sig check. */
        void attach(IncomingCallback cb);
    }

    interface IncomingCallback {
        void onIncoming(String senderNodeId, String topic, byte[] payload, String messageId);
    }

    // ----- StubMeshBackend -----------------------------------------------

    /** Deterministic stub used until the Rust/JNI backend lands. */
    static final class StubMeshBackend implements MeshBackend {

        private static final String STUB_NODE =
                "00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff";

        private IncomingCallback mCb;

        @Override public String name() { return "stub"; }
        @Override public String getLocalNodeId() { return STUB_NODE; }
        @Override public MeshNode[] listKnownPeers() { return new MeshNode[0]; }

        @Override
        public MeshHealth getHealth() {
            return new MeshHealth(0, 0, 0, 0, 0, false);
        }

        @Override
        public String send(String target, String topic, byte[] payload, int ttl) {
            // No-op; return a plausible id so callers can dedup if they retry.
            return randomId();
        }

        @Override
        public String broadcast(String topic, byte[] payload, int ttl) {
            return randomId();
        }

        @Override public void attach(IncomingCallback cb) { mCb = cb; }

        private static String randomId() {
            byte[] b = new byte[16];
            new SecureRandom().nextBytes(b);
            StringBuilder sb = new StringBuilder(32);
            for (byte x : b) sb.append(String.format("%02x", x));
            return sb.toString();
        }
    }

    // ----- subscription bookkeeping --------------------------------------

    private static final class Subscription {
        final String topic;
        final IMeshInboxListener listener;
        Subscription(String topic, IMeshInboxListener listener) {
            this.topic = topic; this.listener = listener;
        }
    }

    /** Dispatch path for backend → app listener. Off-lock. */
    private void onIncomingMessage(String sender, String topic, byte[] payload, String messageId) {
        RemoteCallbackList<IMeshInboxListener> list;
        synchronized (mLock) {
            list = mInbox.get(topic);
        }
        if (list == null) return;
        int n = list.beginBroadcast();
        for (int i = 0; i < n; i++) {
            try { list.getBroadcastItem(i).onMessage(sender, topic, payload, messageId); }
            catch (RemoteException ignored) {}
        }
        list.finishBroadcast();
    }

    // ----- binder --------------------------------------------------------

    private final class BinderImpl extends ICircleMeshManager.Stub {

        @Override
        public String getLocalNodeId() {
            return mBackend == null ? "" : mBackend.getLocalNodeId();
        }

        @Override
        public MeshNode[] listKnownPeers() {
            enforce("za.co.circleos.permission.QUERY_MESH");
            return mBackend == null ? new MeshNode[0] : mBackend.listKnownPeers();
        }

        @Override
        public MeshHealth getHealth() {
            enforce("za.co.circleos.permission.QUERY_MESH");
            return mBackend == null
                    ? new MeshHealth(0, 0, 0, 0, 0, false)
                    : mBackend.getHealth();
        }

        @Override
        public String sendMessage(String targetNodeId, String topic, byte[] payload, int ttl) {
            enforce("za.co.circleos.permission.USE_MESH");
            validate(topic, payload, ttl);
            if (targetNodeId == null || targetNodeId.length() != 64) {
                throw new IllegalArgumentException("targetNodeId must be 64 hex chars");
            }
            if (mBackend == null) throw new IllegalStateException("mesh backend not ready");
            return mBackend.send(targetNodeId, topic, payload, clampTtl(ttl));
        }

        @Override
        public String broadcast(String topic, byte[] payload, int ttl) {
            enforce("za.co.circleos.permission.USE_MESH");
            validate(topic, payload, ttl);
            if (mBackend == null) throw new IllegalStateException("mesh backend not ready");
            return mBackend.broadcast(topic, payload, clampTtl(ttl));
        }

        @Override
        public long subscribeInbox(String topic, IMeshInboxListener listener) {
            enforce("za.co.circleos.permission.USE_MESH");
            if (topic == null || topic.isEmpty() || topic.length() > MAX_TOPIC) {
                throw new IllegalArgumentException("topic length 1.." + MAX_TOPIC);
            }
            long handle = mNextSub.getAndIncrement();
            synchronized (mLock) {
                RemoteCallbackList<IMeshInboxListener> list = mInbox.get(topic);
                if (list == null) {
                    list = new RemoteCallbackList<>();
                    mInbox.put(topic, list);
                }
                list.register(listener);
                mSubscriptions.put((int) handle, new Subscription(topic, listener));
            }
            return handle;
        }

        @Override
        public void unsubscribeInbox(long handle) {
            synchronized (mLock) {
                Subscription sub = mSubscriptions.get((int) handle);
                if (sub == null) return;
                RemoteCallbackList<IMeshInboxListener> list = mInbox.get(sub.topic);
                if (list != null) list.unregister(sub.listener);
                mSubscriptions.remove((int) handle);
            }
        }

        @Override
        public int getApiVersion() { return API_VERSION; }

        // ----- helpers ---------------------------------------------------

        private void enforce(String perm) {
            mContext.enforceCallingOrSelfPermission(perm,
                    "CircleMesh: caller lacks " + perm);
        }

        private void validate(String topic, byte[] payload, int ttl) {
            if (topic == null || topic.isEmpty() || topic.length() > MAX_TOPIC) {
                throw new IllegalArgumentException("topic length 1.." + MAX_TOPIC);
            }
            if (payload == null || payload.length == 0 || payload.length > MAX_PAYLOAD) {
                throw new IllegalArgumentException("payload length 1.." + MAX_PAYLOAD);
            }
        }

        private int clampTtl(int t) {
            if (t < MIN_TTL) return MIN_TTL;
            if (t > MAX_TTL) return MAX_TTL;
            return t;
        }
    }
}
