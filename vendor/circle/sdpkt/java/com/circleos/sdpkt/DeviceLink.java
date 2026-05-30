/*
 * Copyright (C) 2026 The Other Bhengu (PTY) Ltd t/a The Geek Network.
 *
 * One device paired to the wallet. A wallet may have several
 * (e.g. phone + tablet + watch) — each gets an independent device key
 * but shares the wallet's central identity.
 */

package com.circleos.sdpkt;

import android.os.Parcel;
import android.os.Parcelable;

public final class DeviceLink implements Parcelable {

    /** Opaque link id (UUID hex, no dashes). */
    public final String id;

    /** Human-readable device name as it appears in CircleSettings. */
    public final String deviceName;

    /** "phone" | "tablet" | "watch" | "embedded" */
    public final String deviceKind;

    /** ed25519 fingerprint of this device's per-device subkey. */
    public final String devicePubKey;

    /** Unix ms when this device was linked. */
    public final long linkedAtMs;

    /** Unix ms of the most recent activity (any TX or reconcile). */
    public final long lastActiveMs;

    /** Per-device daily spending cap in the wallet's smallest unit. */
    public final long dailyCapMinor;

    /** True if this is the device the caller is running on. */
    public final boolean isThisDevice;

    public DeviceLink(String id,
                      String deviceName,
                      String deviceKind,
                      String devicePubKey,
                      long linkedAtMs,
                      long lastActiveMs,
                      long dailyCapMinor,
                      boolean isThisDevice) {
        this.id            = nz(id);
        this.deviceName    = nz(deviceName);
        this.deviceKind    = nz(deviceKind);
        this.devicePubKey  = nz(devicePubKey);
        this.linkedAtMs    = linkedAtMs;
        this.lastActiveMs  = lastActiveMs;
        this.dailyCapMinor = dailyCapMinor;
        this.isThisDevice  = isThisDevice;
    }

    private static String nz(String s) { return s == null ? "" : s; }

    private DeviceLink(Parcel in) {
        this.id            = in.readString();
        this.deviceName    = in.readString();
        this.deviceKind    = in.readString();
        this.devicePubKey  = in.readString();
        this.linkedAtMs    = in.readLong();
        this.lastActiveMs  = in.readLong();
        this.dailyCapMinor = in.readLong();
        this.isThisDevice  = in.readInt() != 0;
    }

    @Override public void writeToParcel(Parcel o, int f) {
        o.writeString(id);
        o.writeString(deviceName);
        o.writeString(deviceKind);
        o.writeString(devicePubKey);
        o.writeLong(linkedAtMs);
        o.writeLong(lastActiveMs);
        o.writeLong(dailyCapMinor);
        o.writeInt(isThisDevice ? 1 : 0);
    }

    @Override public int describeContents() { return 0; }

    public static final Parcelable.Creator<DeviceLink> CREATOR =
            new Parcelable.Creator<DeviceLink>() {
        @Override public DeviceLink createFromParcel(Parcel in) { return new DeviceLink(in); }
        @Override public DeviceLink[] newArray(int n) { return new DeviceLink[n]; }
    };
}
