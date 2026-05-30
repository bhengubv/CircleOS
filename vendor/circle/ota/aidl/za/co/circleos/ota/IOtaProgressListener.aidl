/*
 * Progress callback for ICircleOtaManager#subscribeProgress.
 *
 * oneway — listeners must return immediately. Settings shows a
 * progress bar by posting these onto its main thread.
 */

package za.co.circleos.ota;

import za.co.circleos.ota.DownloadProgress;

oneway interface IOtaProgressListener {

    /** Fires whenever a chunk lands or a state transition happens. */
    void onProgress(in DownloadProgress progress);

    /**
     * Fires once when the download has fully landed, has been
     * signature-verified, and is ready to apply.
     */
    void onReady(String buildId);

    /**
     * Fires once on terminal failure. Reason:
     *   "signature_mismatch" | "chunk_unavailable" | "disk_full"
     *   | "cancelled" | "origin_unreachable"
     */
    void onFailed(String buildId, String reason);
}
