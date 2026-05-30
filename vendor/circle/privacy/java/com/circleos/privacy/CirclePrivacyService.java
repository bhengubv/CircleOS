/*
 * Copyright (C) 2026 The Other Bhengu (PTY) Ltd t/a The Geek Network.
 *
 * CirclePrivacyService — the SystemService implementation of the Circle
 * Privacy Framework.
 *
 * Lifecycle:
 *   1. SystemServer instantiates and starts this service early in the
 *      BOOT_PHASE_SYSTEM_SERVICES phase, before any third-party apps run.
 *   2. onStart() publishes a binder under the name "circle_privacy" so
 *      callers can reach it via ServiceManager.getService("circle_privacy").
 *   3. onBootPhase(PHASE_BOOT_COMPLETED) hydrates the on-disk state file
 *      (/data/system/circle_privacy.xml) so per-package decisions survive
 *      across reboots.
 *
 * Persistence: a single XML file under /data/system/. We use the
 * AtomicFile pattern so a power loss mid-write doesn't corrupt state.
 *
 * Threading: every binder call enters on a binder thread. All state
 * mutations grab mLock. Reads are also locked because the underlying map
 * is mutable; we can switch to a copy-on-write snapshot later if read
 * contention becomes an issue.
 *
 * Default policy: deny-by-default for INTERNET, fake-response-enabled for
 * all third-party packages. System packages and Circle-signed packages
 * are exempt from both. The exemption list is hard-coded for now;
 * eventually it will be derived from the package's signing cert.
 */

package com.circleos.privacy;

import android.content.Context;
import android.os.Binder;
import android.os.IBinder;
import android.os.SystemProperties;
import android.os.UserHandle;
import android.util.ArrayMap;
import android.util.AtomicFile;
import android.util.Slog;
import android.util.Xml;

import com.android.server.SystemService;

import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;
import org.xmlpull.v1.XmlSerializer;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Map;

import za.co.circleos.privacy.ICirclePrivacyManager;

public final class CirclePrivacyService extends SystemService {

    private static final String TAG = "CirclePrivacy";

    /** Binder name published under ServiceManager. */
    public static final String SERVICE_NAME = "circle_privacy";

    /** Bump on any AIDL shape change. Mirrors {@link ICirclePrivacyManager#getApiVersion}. */
    private static final int API_VERSION = 1;

    /** Where we persist per-package state. /data/system survives factory-reset-preserve. */
    private static final String STATE_FILE = "/data/system/circle_privacy.xml";

    /** Default for new packages: deny network, allow fake responses. */
    private static final boolean DEFAULT_NETWORK_ALLOWED = false;
    private static final boolean DEFAULT_FAKE_RESPONSE_ENABLED = true;

    private final Context mContext;
    private final Object mLock = new Object();

    /** Key: "pkg|userId". Value: PackageState. */
    private final ArrayMap<String, PackageState> mState = new ArrayMap<>();

    private final AtomicFile mStateFile;
    private final BinderImpl mBinder;

    public CirclePrivacyService(Context context) {
        super(context);
        mContext = context;
        mStateFile = new AtomicFile(new File(STATE_FILE));
        mBinder = new BinderImpl();
    }

    @Override
    public void onStart() {
        Slog.i(TAG, "starting (api=" + API_VERSION + ", build="
                + SystemProperties.get("ro.circleos.build", "0") + ")");
        publishBinderService(SERVICE_NAME, mBinder);
    }

    @Override
    public void onBootPhase(int phase) {
        if (phase == PHASE_SYSTEM_SERVICES_READY) {
            synchronized (mLock) {
                loadStateLocked();
            }
            Slog.i(TAG, "loaded state, tracking " + mState.size() + " packages");
        }
    }

    // ----- persistence ----------------------------------------------------

    private void loadStateLocked() {
        FileInputStream in = null;
        try {
            in = mStateFile.openRead();
            XmlPullParser p = Xml.newPullParser();
            p.setInput(in, StandardCharsets.UTF_8.name());

            int event;
            while ((event = p.next()) != XmlPullParser.END_DOCUMENT) {
                if (event != XmlPullParser.START_TAG) continue;
                if (!"package".equals(p.getName())) continue;

                String pkg = p.getAttributeValue(null, "name");
                int uid = parseIntOr(p.getAttributeValue(null, "userId"), 0);
                boolean net = "1".equals(p.getAttributeValue(null, "net"));
                boolean fake = !"0".equals(p.getAttributeValue(null, "fake"));
                if (pkg != null) {
                    mState.put(key(pkg, uid), new PackageState(net, fake));
                }
            }
        } catch (FileNotFoundException e) {
            // First boot — nothing to load. Defaults will apply on first lookup.
        } catch (XmlPullParserException | IOException e) {
            Slog.e(TAG, "loadState failed; starting from defaults", e);
            mState.clear();
        } finally {
            try { if (in != null) in.close(); } catch (IOException ignored) {}
        }
    }

    private void persistStateLocked() {
        FileOutputStream out = null;
        try {
            out = mStateFile.startWrite();
            XmlSerializer s = Xml.newSerializer();
            s.setOutput(out, StandardCharsets.UTF_8.name());
            s.startDocument(null, true);
            s.startTag(null, "circle-privacy");
            s.attribute(null, "version", Integer.toString(API_VERSION));
            for (Map.Entry<String, PackageState> e : mState.entrySet()) {
                String[] parts = e.getKey().split("\\|", 2);
                PackageState ps = e.getValue();
                s.startTag(null, "package");
                s.attribute(null, "name", parts[0]);
                s.attribute(null, "userId", parts[1]);
                s.attribute(null, "net", ps.networkAllowed ? "1" : "0");
                s.attribute(null, "fake", ps.fakeResponseEnabled ? "1" : "0");
                s.endTag(null, "package");
            }
            s.endTag(null, "circle-privacy");
            s.endDocument();
            mStateFile.finishWrite(out);
        } catch (IOException e) {
            Slog.e(TAG, "persistState failed; rolling back", e);
            if (out != null) mStateFile.failWrite(out);
        }
    }

    private static int parseIntOr(String s, int dflt) {
        if (s == null) return dflt;
        try { return Integer.parseInt(s); } catch (NumberFormatException e) { return dflt; }
    }

    private static String key(String pkg, int userId) {
        return pkg + "|" + userId;
    }

    // ----- exemption policy ----------------------------------------------

    /**
     * Returns true for packages we should NOT treat as third-party — the
     * OS itself, Circle-signed packages, and known-good privileged apps.
     * They always get network access and never get fake responses.
     *
     * This is a placeholder until we wire up signing-cert checks. For now,
     * exempt the "android" pseudo-package and anything in com.android.* /
     * com.circleos.*.
     */
    private static boolean isExempt(String pkg) {
        if (pkg == null) return true;
        if ("android".equals(pkg)) return true;
        if (pkg.startsWith("com.android.")) return true;
        if (pkg.startsWith("com.circleos.")) return true;
        if (pkg.startsWith("za.co.circleos.")) return true;
        return false;
    }

    // ----- binder implementation -----------------------------------------

    private final class BinderImpl extends ICirclePrivacyManager.Stub {

        @Override
        public boolean isNetworkAllowed(String packageName, int userId) {
            if (isExempt(packageName)) return true;
            synchronized (mLock) {
                PackageState ps = mState.get(key(packageName, userId));
                return ps == null ? DEFAULT_NETWORK_ALLOWED : ps.networkAllowed;
            }
        }

        @Override
        public void setNetworkAllowed(String packageName, int userId, boolean allowed) {
            enforceManagePrivacy();
            synchronized (mLock) {
                PackageState ps = mState.get(key(packageName, userId));
                if (ps == null) {
                    ps = new PackageState(DEFAULT_NETWORK_ALLOWED, DEFAULT_FAKE_RESPONSE_ENABLED);
                    mState.put(key(packageName, userId), ps);
                }
                ps.networkAllowed = allowed;
                persistStateLocked();
            }
            Slog.i(TAG, "setNetworkAllowed " + packageName + " u" + userId + " = " + allowed);
        }

        @Override
        public boolean isFakeResponseEnabled(String packageName, int userId) {
            if (isExempt(packageName)) return false;
            synchronized (mLock) {
                PackageState ps = mState.get(key(packageName, userId));
                return ps == null ? DEFAULT_FAKE_RESPONSE_ENABLED : ps.fakeResponseEnabled;
            }
        }

        @Override
        public void setFakeResponseEnabled(String packageName, int userId, boolean enabled) {
            enforceManagePrivacy();
            synchronized (mLock) {
                PackageState ps = mState.get(key(packageName, userId));
                if (ps == null) {
                    ps = new PackageState(DEFAULT_NETWORK_ALLOWED, DEFAULT_FAKE_RESPONSE_ENABLED);
                    mState.put(key(packageName, userId), ps);
                }
                ps.fakeResponseEnabled = enabled;
                persistStateLocked();
            }
            Slog.i(TAG, "setFakeResponseEnabled " + packageName + " u" + userId + " = " + enabled);
        }

        @Override
        public int getApiVersion() {
            return API_VERSION;
        }

        /**
         * Throw SecurityException unless the caller holds
         * za.co.circleos.permission.MANAGE_PRIVACY. The shell uid and
         * system uid are allowed unconditionally so adb / system_server
         * can drive the service for diagnostics.
         */
        private void enforceManagePrivacy() {
            int callingUid = Binder.getCallingUid();
            if (callingUid == 0 /* root */
                    || callingUid == android.os.Process.SYSTEM_UID
                    || callingUid == android.os.Process.SHELL_UID) {
                return;
            }
            mContext.enforceCallingPermission(
                    "za.co.circleos.permission.MANAGE_PRIVACY",
                    "CirclePrivacy: caller " + callingUid + " lacks MANAGE_PRIVACY");
        }
    }

    /** Per-package settings. Trivial value class — fields mutated under mLock. */
    private static final class PackageState {
        boolean networkAllowed;
        boolean fakeResponseEnabled;
        PackageState(boolean net, boolean fake) {
            this.networkAllowed = net;
            this.fakeResponseEnabled = fake;
        }
    }
}
