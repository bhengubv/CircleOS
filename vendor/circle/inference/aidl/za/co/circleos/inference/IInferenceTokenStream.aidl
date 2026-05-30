/*
 * Streaming token callback for ICircleInferenceManager#startCompletion.
 *
 * Implementations must return quickly from onToken — the binder thread is
 * the generation thread and any blocking in the callback stalls token
 * production. If you need to do non-trivial work (e.g. UI update), post
 * to a different thread and return immediately.
 */

package za.co.circleos.inference;

oneway interface IInferenceTokenStream {

    /**
     * One or more newly-generated tokens, already decoded to text. The
     * chunk is concatenable with previous chunks to form the full
     * completion so far. Chunks may be single tokens or short runs.
     *
     * @param chunk     decoded text fragment from the model
     * @param tokenIdx  zero-based index of the chunk in this generation
     */
    void onToken(String chunk, int tokenIdx);

    /**
     * Generation finished. Always called exactly once, after the final
     * onToken (or zero onTokens if generation failed before producing
     * any output).
     *
     * Possible reasons:
     *   "eot"        — model emitted end-of-text token
     *   "max_tokens" — hit the maxTokens cap
     *   "stop"       — emitted one of the caller's stop strings
     *   "cancelled"  — caller invoked cancel()
     *   "error:<msg>" — internal error; <msg> is a short diagnostic
     */
    void onComplete(String reason, int totalTokens);
}
