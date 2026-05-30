/*
 * Copyright (C) 2026 The Other Bhengu (PTY) Ltd t/a The Geek Network.
 *
 * AIDL surface for the Circle Inference Service.
 *
 * The service runs a small LLM (BitNet 1B at v0, swappable later) on-device
 * via a JNI binding to llama.cpp. It exposes two access modes:
 *
 *   1. This binder, for in-process / system callers — fastest, no
 *      serialisation overhead beyond the AIDL marshalling.
 *
 *   2. A loopback HTTP listener at 127.0.0.1:11434 (the Ollama protocol),
 *      so any .NET / Python / native client that already speaks Ollama can
 *      talk to it unchanged. The InferenceBridge app is the front door
 *      for that surface.
 *
 * Callers must hold za.co.circleos.permission.ACCESS_INFERENCE.
 *
 * Everything is streamed: the {@link IInferenceTokenStream} callback
 * receives partial token strings as the model produces them, so the
 * caller can render a typing UI without waiting for completion.
 */

package za.co.circleos.inference;

import za.co.circleos.inference.IInferenceTokenStream;

/** Binder published under SERVICE_NAME = "circle_inference". */
interface ICircleInferenceManager {

    /**
     * Returns the model identifier currently loaded into RAM.
     * Format: "<family>:<size>:<quant>" — e.g. "bitnet:1b:b1.58", or
     * the empty string if no model is loaded yet.
     */
    String getActiveModelId();

    /**
     * Begin a streaming completion against the active model. The token
     * stream callback is invoked on a binder thread for each chunk; the
     * caller must not block in the callback or it will stall generation.
     *
     * @param prompt       full prompt, no automatic chat templating
     * @param maxTokens    hard cap on output token count (1..2048)
     * @param temperature  sampling temperature, 0.0 = greedy, typical 0.7
     * @param topP         nucleus sampling cutoff, 1.0 disables
     * @param stop         array of stop strings (empty = none)
     * @param stream       callback receiving token chunks and completion
     * @return generation handle that can be passed to {@link #cancel}
     */
    long startCompletion(in String prompt,
                         int maxTokens,
                         float temperature,
                         float topP,
                         in String[] stop,
                         in IInferenceTokenStream stream);

    /**
     * Request cancellation of a streaming generation. The token stream's
     * onComplete will fire shortly after with reason = "cancelled".
     */
    void cancel(long handle);

    /**
     * Returns true if the service is healthy enough to accept a new
     * startCompletion call. False during model load, OOM recovery, or
     * when the model file is missing.
     */
    boolean isReady();

    /**
     * Number of currently running completions across all callers. Caller
     * may use this to back off when the device is busy.
     */
    int getActiveGenerationCount();

    /** Schema version. Mirrors the framework's API_VERSION constant. */
    int getApiVersion();
}
