/*
 * Copyright (C) 2026 The Other Bhengu (PTY) Ltd t/a The Geek Network.
 *
 * CircleInferenceService — SystemService impl for the Circle Inference
 * Service.
 *
 * Lifecycle:
 *   1. Started by SystemServer in startOtherServices (see
 *      patches/frameworks-base/0003-systemserver-start-circle-inference.patch
 *      — to be added once Privacy v0 is proven).
 *   2. onStart() publishes the "circle_inference" binder.
 *   3. onBootPhase(PHASE_BOOT_COMPLETED) attempts to load the active
 *      model. Failure is non-fatal: the service stays up but isReady()
 *      reports false until a model is available.
 *
 * v0 model backend: STUB. The native llama.cpp + BitNet binding lands
 * in a follow-up. The stub implements the same Completer interface and
 * emits a recognisable "stub" response so we can validate the full
 * binder/HTTP/Ollama-compat path end-to-end on a real device before
 * the native code is integrated.
 *
 * Threading model:
 *   - All AIDL methods enter on binder threads; state under mLock.
 *   - Each active completion runs on a worker thread pulled from
 *     mGenerationExecutor. The worker pushes tokens to the caller's
 *     IInferenceTokenStream and finalises with onComplete.
 *   - cancel(handle) flips a per-generation volatile flag the worker
 *     polls; workers stop on the next token boundary.
 */

package com.circleos.inference;

import android.content.Context;
import android.os.IBinder;
import android.os.RemoteException;
import android.os.SystemProperties;
import android.util.Slog;
import android.util.SparseArray;

import com.android.server.SystemService;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;

import za.co.circleos.inference.ICircleInferenceManager;
import za.co.circleos.inference.IInferenceTokenStream;

public final class CircleInferenceService extends SystemService {

    private static final String TAG = "CircleInference";
    public static final String SERVICE_NAME = "circle_inference";
    private static final int API_VERSION = 1;

    /** Concurrent active generations. Token rate × concurrency is the budget. */
    private static final int MAX_CONCURRENT_GENERATIONS = 2;

    private final Context mContext;
    private final Object mLock = new Object();
    private final BinderImpl mBinder;
    private final ExecutorService mGenerationExecutor;
    private final SparseArray<Generation> mActive = new SparseArray<>();
    private final AtomicLong mNextHandle = new AtomicLong(1);

    /** The pluggable text generator. Replaced with a llama.cpp-backed
     *  implementation once the JNI binding lands. */
    private Completer mCompleter;

    public CircleInferenceService(Context context) {
        super(context);
        mContext = context;
        mBinder = new BinderImpl();
        mGenerationExecutor = Executors.newFixedThreadPool(MAX_CONCURRENT_GENERATIONS,
                r -> {
                    Thread t = new Thread(r, "circle-inference");
                    t.setDaemon(true);
                    t.setPriority(Thread.NORM_PRIORITY - 1);
                    return t;
                });
    }

    @Override
    public void onStart() {
        Slog.i(TAG, "starting (api=" + API_VERSION + ")");
        publishBinderService(SERVICE_NAME, mBinder);
    }

    @Override
    public void onBootPhase(int phase) {
        if (phase == PHASE_BOOT_COMPLETED) {
            // Stub completer for v0; replace with NativeLlamaCompleter once JNI lands.
            mCompleter = new StubCompleter();
            Slog.i(TAG, "loaded completer: " + mCompleter.getModelId());
        }
    }

    // ----- the Completer abstraction --------------------------------------

    /**
     * Pluggable generator. StubCompleter is v0; the real implementation
     * will load a gguf model via the llama.cpp JNI bridge and stream
     * tokens through onToken.
     */
    interface Completer {
        /** "family:size:quant" identifier. */
        String getModelId();
        /** Is a model loaded and ready to generate? */
        boolean isReady();
        /**
         * Synchronous, blocking generation. The {@code cancelled} flag is
         * polled between tokens; when set the loop terminates early and
         * onComplete fires with reason="cancelled".
         */
        void generate(String prompt,
                      int maxTokens,
                      float temperature,
                      float topP,
                      String[] stop,
                      AtomicBoolean cancelled,
                      IInferenceTokenStream out);
    }

    // ----- StubCompleter --------------------------------------------------

    /** Deterministic synthetic completer used until the native bridge lands. */
    static final class StubCompleter implements Completer {

        private static final String MODEL_ID = "stub:hello:v0";

        @Override public String getModelId() { return MODEL_ID; }
        @Override public boolean isReady() { return true; }

        @Override
        public void generate(String prompt,
                             int maxTokens,
                             float temperature,
                             float topP,
                             String[] stop,
                             AtomicBoolean cancelled,
                             IInferenceTokenStream out) {
            // Emit a recognisable, easily-greppable response so on-device
            // smoke tests can tell the stub apart from a real model.
            String reply = "[CircleOS inference stub v0] you said: "
                    + (prompt == null ? "" : prompt.trim());
            int idx = 0;
            // Stream word-by-word so the IInferenceTokenStream behaviour
            // matches a real model's chunked output.
            for (String word : reply.split("(?<=\\s)")) {
                if (cancelled.get()) {
                    safeOnComplete(out, "cancelled", idx);
                    return;
                }
                if (idx >= maxTokens) {
                    safeOnComplete(out, "max_tokens", idx);
                    return;
                }
                try { out.onToken(word, idx); } catch (RemoteException e) {
                    // Caller died; abandon quietly.
                    return;
                }
                idx++;
                // Small delay so subscribers can observe streaming.
                try { Thread.sleep(20); } catch (InterruptedException ignored) {
                    Thread.currentThread().interrupt();
                    safeOnComplete(out, "cancelled", idx); return;
                }
            }
            safeOnComplete(out, "eot", idx);
        }

        private static void safeOnComplete(IInferenceTokenStream out, String reason, int total) {
            try { out.onComplete(reason, total); }
            catch (RemoteException e) { /* caller gone, no-op */ }
        }
    }

    // ----- per-generation bookkeeping ------------------------------------

    private static final class Generation {
        final long handle;
        final AtomicBoolean cancelled = new AtomicBoolean(false);
        Generation(long handle) { this.handle = handle; }
    }

    // ----- binder --------------------------------------------------------

    private final class BinderImpl extends ICircleInferenceManager.Stub {

        @Override
        public String getActiveModelId() {
            Completer c = mCompleter;
            return c == null ? "" : c.getModelId();
        }

        @Override
        public long startCompletion(String prompt,
                                    int maxTokens,
                                    float temperature,
                                    float topP,
                                    String[] stop,
                                    IInferenceTokenStream stream) {
            enforceAccessInference();

            final Completer completer = mCompleter;
            if (completer == null || !completer.isReady()) {
                throw new IllegalStateException("inference not ready");
            }
            if (maxTokens < 1) throw new IllegalArgumentException("maxTokens<1");
            if (maxTokens > 2048) maxTokens = 2048;

            final long handle = mNextHandle.getAndIncrement();
            final Generation gen = new Generation(handle);
            final int cap = maxTokens;
            final float temp = temperature;
            final float p = topP;
            final String[] stops = stop == null ? new String[0] : stop;

            synchronized (mLock) {
                if (mActive.size() >= MAX_CONCURRENT_GENERATIONS) {
                    throw new IllegalStateException("inference busy: max concurrency reached");
                }
                mActive.put((int) handle, gen);
            }

            mGenerationExecutor.submit(() -> {
                try {
                    completer.generate(prompt, cap, temp, p, stops, gen.cancelled, stream);
                } catch (Throwable t) {
                    Slog.w(TAG, "generation " + handle + " failed", t);
                    try { stream.onComplete("error:" + t.getClass().getSimpleName(), 0); }
                    catch (RemoteException ignored) {}
                } finally {
                    synchronized (mLock) { mActive.remove((int) handle); }
                }
            });

            return handle;
        }

        @Override
        public void cancel(long handle) {
            enforceAccessInference();
            synchronized (mLock) {
                Generation g = mActive.get((int) handle);
                if (g != null) g.cancelled.set(true);
            }
        }

        @Override
        public boolean isReady() {
            Completer c = mCompleter;
            return c != null && c.isReady();
        }

        @Override
        public int getActiveGenerationCount() {
            synchronized (mLock) { return mActive.size(); }
        }

        @Override
        public int getApiVersion() { return API_VERSION; }

        private void enforceAccessInference() {
            mContext.enforceCallingOrSelfPermission(
                    "za.co.circleos.permission.ACCESS_INFERENCE",
                    "CircleInference: caller lacks ACCESS_INFERENCE");
        }
    }
}
