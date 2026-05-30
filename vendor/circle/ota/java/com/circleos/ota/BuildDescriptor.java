/*
 * Copyright (C) 2026 The Other Bhengu (PTY) Ltd t/a The Geek Network.
 *
 * Describes one Circle OS build. Returned by getCurrentBuild /
 * getLatestAvailable.
 */

package com.circleos.ota;

import android.os.Parcel;
import android.os.Parcelable;

public final class BuildDescriptor implements Parcelable {

    /** Stable id for this build, e.g. "circleos-0.2.0-arm64-20260530-abc123". */
    public final String buildId;

    /** Semantic version, e.g. "0.2.0". */
    public final String version;

    /** Channel: "stable" | "beta" | "dev" | "internal". */
    public final String channel;

    /** Unix ms when the build was produced. */
    public final long buildAtMs;

    /** Total system image size in bytes. */
    public final long sizeBytes;

    /**
     * SHA-256 of the signed manifest (hex). Verifies the manifest the
     * device pulled actually came from a trusted origin key.
     */
    public final String manifestSha256;

    /**
     * Hex of the build's source-tree commit SHA, for traceability. May
     * be empty for internal/test builds.
     */
    public final String sourceCommit;

    /** A user-facing changelog blurb. May be empty. */
    public final String changelog;

    public BuildDescriptor(String buildId,
                           String version,
                           String channel,
                           long buildAtMs,
                           long sizeBytes,
                           String manifestSha256,
                           String sourceCommit,
                           String changelog) {
        this.buildId        = nz(buildId);
        this.version        = nz(version);
        this.channel        = nz(channel);
        this.buildAtMs      = buildAtMs;
        this.sizeBytes      = sizeBytes;
        this.manifestSha256 = nz(manifestSha256);
        this.sourceCommit   = nz(sourceCommit);
        this.changelog      = nz(changelog);
    }

    private static String nz(String s) { return s == null ? "" : s; }

    private BuildDescriptor(Parcel in) {
        this.buildId        = in.readString();
        this.version        = in.readString();
        this.channel        = in.readString();
        this.buildAtMs      = in.readLong();
        this.sizeBytes      = in.readLong();
        this.manifestSha256 = in.readString();
        this.sourceCommit   = in.readString();
        this.changelog      = in.readString();
    }

    @Override public void writeToParcel(Parcel o, int f) {
        o.writeString(buildId);
        o.writeString(version);
        o.writeString(channel);
        o.writeLong(buildAtMs);
        o.writeLong(sizeBytes);
        o.writeString(manifestSha256);
        o.writeString(sourceCommit);
        o.writeString(changelog);
    }

    @Override public int describeContents() { return 0; }

    public static final Parcelable.Creator<BuildDescriptor> CREATOR =
            new Parcelable.Creator<BuildDescriptor>() {
        @Override public BuildDescriptor createFromParcel(Parcel in) { return new BuildDescriptor(in); }
        @Override public BuildDescriptor[] newArray(int n) { return new BuildDescriptor[n]; }
    };
}
