/*
 * Copyright (C) 2026 The Other Bhengu (PTY) Ltd t/a The Geek Network.
 *
 * Snapshot of an OTA download in flight. Status UIs poll this; the
 * IOtaProgressListener callback also delivers fresh ones on every
 * chunk landing.
 */

package com.circleos.ota;

import android.os.Parcel;
import android.os.Parcelable;

public final class DownloadProgress implements Parcelable {

    public final String buildId;

    /** "queued" | "downloading" | "paused" | "verifying" | "ready"
     *  | "applying" | "failed" */
    public final String state;

    /** Bytes fetched so far across all sources. */
    public final long bytesFetched;

    /** Total bytes that need to be fetched. */
    public final long bytesTotal;

    /** Bytes/sec moving average over the last 30 s. */
    public final long bytesPerSec;

    /** How many chunks came from the origin (vs peers). */
    public final int chunksFromOrigin;

    /** How many chunks came from LAN / mesh peers — proves the P2P
     *  delivery is doing something. */
    public final int chunksFromPeers;

    public DownloadProgress(String buildId,
                            String state,
                            long bytesFetched,
                            long bytesTotal,
                            long bytesPerSec,
                            int chunksFromOrigin,
                            int chunksFromPeers) {
        this.buildId          = nz(buildId);
        this.state            = nz(state);
        this.bytesFetched     = bytesFetched;
        this.bytesTotal       = bytesTotal;
        this.bytesPerSec      = bytesPerSec;
        this.chunksFromOrigin = chunksFromOrigin;
        this.chunksFromPeers  = chunksFromPeers;
    }

    private static String nz(String s) { return s == null ? "" : s; }

    private DownloadProgress(Parcel in) {
        this.buildId          = in.readString();
        this.state            = in.readString();
        this.bytesFetched     = in.readLong();
        this.bytesTotal       = in.readLong();
        this.bytesPerSec      = in.readLong();
        this.chunksFromOrigin = in.readInt();
        this.chunksFromPeers  = in.readInt();
    }

    @Override public void writeToParcel(Parcel o, int f) {
        o.writeString(buildId);
        o.writeString(state);
        o.writeLong(bytesFetched);
        o.writeLong(bytesTotal);
        o.writeLong(bytesPerSec);
        o.writeInt(chunksFromOrigin);
        o.writeInt(chunksFromPeers);
    }

    @Override public int describeContents() { return 0; }

    public static final Parcelable.Creator<DownloadProgress> CREATOR =
            new Parcelable.Creator<DownloadProgress>() {
        @Override public DownloadProgress createFromParcel(Parcel in) { return new DownloadProgress(in); }
        @Override public DownloadProgress[] newArray(int n) { return new DownloadProgress[n]; }
    };
}
