/*
 * Copyright (C) 2026 The Other Bhengu (PTY) Ltd t/a The Geek Network.
 *
 * One outbound flow observed by the Traffic Lobby VPN.
 *
 * Captured at DNS-resolution / connection-establishment time and pruned
 * after a configurable window (default 24 h). Used for the "where did
 * my apps phone?" status UI and as the input to the DGA entropy detector.
 */

package com.circleos.security;

import android.os.Parcel;
import android.os.Parcelable;

public final class TrafficEvent implements Parcelable {

    /** Unix ms timestamp the flow was observed. */
    public final long timestampMs;

    /** Package name of the app that opened the flow, or "" if unknown. */
    public final String packageName;

    /** Hostname queried via DNS, or "" if direct-by-IP. */
    public final String hostname;

    /** Remote IP (after resolution), or "" if resolution failed. */
    public final String remoteIp;

    /** TCP/UDP port. -1 means unknown / non-TCP. */
    public final int remotePort;

    /** Bytes sent in this flow's lifetime (0 = none yet). */
    public final long bytesSent;

    /** Bytes received. */
    public final long bytesReceived;

    /** Verdict from the IOC feed at the moment of capture:
     *   "clean"   — not on any list
     *   "blocked" — matched a deny entry; the flow was severed
     *   "warned"  — matched a watch entry; the user was notified
     *   "unknown" — not yet looked up (feed offline / new domain) */
    public final String verdict;

    /** DGA entropy score 0.0..1.0; > 0.8 typically indicates DGA. */
    public final float dgaEntropy;

    public TrafficEvent(long timestampMs,
                        String packageName,
                        String hostname,
                        String remoteIp,
                        int remotePort,
                        long bytesSent,
                        long bytesReceived,
                        String verdict,
                        float dgaEntropy) {
        this.timestampMs   = timestampMs;
        this.packageName   = nz(packageName);
        this.hostname      = nz(hostname);
        this.remoteIp      = nz(remoteIp);
        this.remotePort    = remotePort;
        this.bytesSent     = bytesSent;
        this.bytesReceived = bytesReceived;
        this.verdict       = nz(verdict);
        this.dgaEntropy    = dgaEntropy;
    }

    private static String nz(String s) { return s == null ? "" : s; }

    private TrafficEvent(Parcel in) {
        this.timestampMs   = in.readLong();
        this.packageName   = in.readString();
        this.hostname      = in.readString();
        this.remoteIp      = in.readString();
        this.remotePort    = in.readInt();
        this.bytesSent     = in.readLong();
        this.bytesReceived = in.readLong();
        this.verdict       = in.readString();
        this.dgaEntropy    = in.readFloat();
    }

    @Override public void writeToParcel(Parcel o, int f) {
        o.writeLong(timestampMs);
        o.writeString(packageName);
        o.writeString(hostname);
        o.writeString(remoteIp);
        o.writeInt(remotePort);
        o.writeLong(bytesSent);
        o.writeLong(bytesReceived);
        o.writeString(verdict);
        o.writeFloat(dgaEntropy);
    }

    @Override public int describeContents() { return 0; }

    public static final Parcelable.Creator<TrafficEvent> CREATOR =
            new Parcelable.Creator<TrafficEvent>() {
        @Override public TrafficEvent createFromParcel(Parcel in) { return new TrafficEvent(in); }
        @Override public TrafficEvent[] newArray(int n) { return new TrafficEvent[n]; }
    };
}
