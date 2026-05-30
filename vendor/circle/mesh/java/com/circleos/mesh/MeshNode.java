/*
 * Copyright (C) 2026 The Other Bhengu (PTY) Ltd t/a The Geek Network.
 *
 * Snapshot of one mesh peer. Returned by ICircleMeshManager#listKnownPeers.
 */

package com.circleos.mesh;

import android.os.Parcel;
import android.os.Parcelable;

public final class MeshNode implements Parcelable {

    /** Ed25519 public-key fingerprint, hex (64 chars). */
    public final String nodeId;

    /** Optional human-readable label the peer announced. May be empty. */
    public final String displayName;

    /** Bitmask of transports we can currently reach this peer on:
     *  1 = WiFi Direct, 2 = BLE, 4 = LoRa. */
    public final int transports;

    /** Estimated hop count to this peer (1 = direct neighbour). */
    public final int hopCount;

    /** Unix ms timestamp of the most recent message from this peer. */
    public final long lastSeenMs;

    /** RSSI of the strongest current radio link, or 0 if unknown / LoRa. */
    public final int rssiDbm;

    public MeshNode(String nodeId,
                    String displayName,
                    int transports,
                    int hopCount,
                    long lastSeenMs,
                    int rssiDbm) {
        this.nodeId = nodeId;
        this.displayName = displayName == null ? "" : displayName;
        this.transports = transports;
        this.hopCount = hopCount;
        this.lastSeenMs = lastSeenMs;
        this.rssiDbm = rssiDbm;
    }

    private MeshNode(Parcel in) {
        this.nodeId      = in.readString();
        this.displayName = in.readString();
        this.transports  = in.readInt();
        this.hopCount    = in.readInt();
        this.lastSeenMs  = in.readLong();
        this.rssiDbm     = in.readInt();
    }

    @Override public void writeToParcel(Parcel o, int f) {
        o.writeString(nodeId);
        o.writeString(displayName);
        o.writeInt(transports);
        o.writeInt(hopCount);
        o.writeLong(lastSeenMs);
        o.writeInt(rssiDbm);
    }

    @Override public int describeContents() { return 0; }

    public static final Parcelable.Creator<MeshNode> CREATOR =
            new Parcelable.Creator<MeshNode>() {
        @Override public MeshNode createFromParcel(Parcel in) { return new MeshNode(in); }
        @Override public MeshNode[] newArray(int n) { return new MeshNode[n]; }
    };

    @Override public String toString() {
        return "MeshNode{" + nodeId.substring(0, Math.min(8, nodeId.length()))
                + "..., t=" + transports + ", h=" + hopCount + "}";
    }
}
