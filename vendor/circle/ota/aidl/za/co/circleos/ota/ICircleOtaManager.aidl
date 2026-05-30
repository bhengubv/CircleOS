/*
 * Copyright (C) 2026 The Other Bhengu (PTY) Ltd t/a The Geek Network.
 *
 * AIDL surface for the Circle OTA Service.
 *
 * Update delivery model:
 *   1. The device periodically asks an enrollment-bound origin for the
 *      latest available build (HTTPS, signed manifest).
 *   2. The image is split into ~1 MiB chunks. Each chunk is content-
 *      addressed by SHA-256.
 *   3. Chunks are pulled from whichever is fastest: origin HTTPS,
 *      peers on the same WiFi LAN, or peers in the CircleMesh
 *      (BLE / WiFi Direct / LoRa where available).
 *   4. Once all chunks land, the service writes the inactive A/B slot,
 *      verifies the slot's signature, and asks the user to reboot.
 *
 * Permissions:
 *   - QUERY_OTA: read build status, progress (status UI)
 *   - TRIGGER_OTA: start a check/download (Settings app)
 *   - APPLY_OTA: actually reboot into the new slot (signature|privileged)
 *   - MANAGE_ENROLLMENT: change the origin (signature|privileged)
 */

package za.co.circleos.ota;

import za.co.circleos.ota.BuildDescriptor;
import za.co.circleos.ota.DownloadProgress;
import za.co.circleos.ota.IOtaProgressListener;

/** Binder published under SERVICE_NAME = "circle_ota". */
interface ICircleOtaManager {

    // ----- introspection ---------------------------------------------

    /** The build currently running on the device. */
    BuildDescriptor getCurrentBuild();

    /**
     * The latest build the origin advertised (or null-ish empty fields
     * if the device has never successfully checked).
     */
    BuildDescriptor getLatestAvailable();

    // ----- flow control ----------------------------------------------

    /** Ask the origin "is there anything newer than current?". */
    void checkForUpdate();

    /**
     * Begin downloading {@code buildId}. Idempotent: re-calling with the
     * same id resumes from the partial state on disk.
     */
    void startDownload(in String buildId);

    /** Pause an in-progress download. */
    void pauseDownload(in String buildId);

    /** Cancel a download and free its chunks. */
    void cancelDownload(in String buildId);

    /**
     * Stage the downloaded build into the inactive A/B slot and reboot.
     * APPLY_OTA + fresh lock-screen auth required.
     */
    void applyUpdate(in String buildId, boolean forceReboot);

    /** Current download progress for the given buildId. */
    DownloadProgress getProgress(in String buildId);

    // ----- subscriptions ---------------------------------------------

    long subscribeProgress(in IOtaProgressListener listener);
    void unsubscribeProgress(long handle);

    // ----- versioning ------------------------------------------------

    int getApiVersion();
}
