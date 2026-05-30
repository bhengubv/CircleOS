/*
 * Copyright (C) 2026 The Other Bhengu (PTY) Ltd t/a The Geek Network.
 *
 * Cheap-to-query snapshot of mesh service state. Status UIs poll this.
 */

package com.circleos.mesh;

import android.os.Parcel;
import android.os.Parcelable;

public final class MeshHealth implements Parcelable {

    /** Number of peers currently reachable on any transport. */
    public final int peerCount;

    /** Messages sent in the last 60 s (best-effort). */
    public final int sentLastMinute;

    /** Messages received and de-duplicated in the last 60 s. */
    public final int receivedLastMinute;

    /** Messages forwarded on behalf of others in the last 60 s. */
    public final int forwardedLastMinute;

    /** Bitmask of transports currently UP: 1=WiFi-Direct, 2=BLE, 4=LoRa. */
    public final int activeTransports;

    /** True if the mesh service believes it is healthy enough to send. */
    public final boolean healthy;

    public MeshHealth(int peerCount,
                      int sentLastMinute,
                      int receivedLastMinute,
                      int forwardedLastMinute,
                      int activeTransports,
                      boolean healthy) {
        this.peerCount           = peerCount;
        this.sentLastMinute      = sentLastMinute;
        this.receivedLastMinute  = receivedLastMinute;
        this.forwardedLastMinute = forwardedLastMinute;
        this.activeTransports    = activeTransports;
        this.healthy             = healthy;
    }

    private MeshHealth(Parcel in) {
        this.peerCount           = in.readInt();
        this.sentLastMinute      = in.readInt();
        this.receivedLastMinute  = in.readInt();
        this.forwardedLastMinute = in.readInt();
        this.activeTransports    = in.readInt();
        this.healthy             = in.readInt() != 0;
    }

    @Override public void writeToParcel(Parcel o, int f) {
        o.writeInt(peerCount);
        o.writeInt(sentLastMinute);
        o.writeInt(receivedLastMinute);
        o.writeInt(forwardedLastMinute);
        o.writeInt(activeTransports);
        o.writeInt(healthy ? 1 : 0);
    }

    @Override public int describeContents() { return 0; }

    public static final Parcelable.Creator<MeshHealth> CREATOR =
            new Parcelable.Creator<MeshHealth>() {
        @Override public MeshHealth createFromParcel(Parcel in) { return new MeshHealth(in); }
        @Override public MeshHealth[] newArray(int n) { return new MeshHealth[n]; }
    };

    @Override public String toString() {
        return "MeshHealth{peers=" + peerCount
                + ", tx=" + sentLastMinute
                + ", rx=" + receivedLastMinute
                + ", fwd=" + forwardedLastMinute
                + ", tr=" + activeTransports
                + ", up=" + healthy + "}";
    }
}
