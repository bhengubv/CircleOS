/*
 * Copyright (C) 2026 The Other Bhengu (PTY) Ltd t/a The Geek Network.
 *
 * Metadata about a file currently held in the File DMZ.
 *
 * The actual file body lives under /data/circle/dmz/<id>; CircleSettings
 * never exposes that path to apps. The CDR pipeline writes the
 * reconstructed body to /data/media/0/Download/ when (a) CDR succeeds
 * and (b) the user has reviewed the verdict.
 */

package com.circleos.security;

import android.os.Parcel;
import android.os.Parcelable;

public final class QuarantinedFile implements Parcelable {

    /** Opaque id, stable for the lifetime of the quarantine entry. */
    public final String quarantineId;

    /** Original filename the source provided (sanitised). */
    public final String originalName;

    /** Package that produced the download, or "" if unknown. */
    public final String sourcePackage;

    /** Source URL if known, or "". */
    public final String sourceUrl;

    /** MIME type sniffed from the body. */
    public final String mimeType;

    /** SHA-256 hex of the original body. */
    public final String sha256;

    /** Size in bytes. */
    public final long sizeBytes;

    /** Unix ms timestamp of arrival. */
    public final long quarantinedAtMs;

    /** CDR pipeline state:
     *   "pending"  — not yet scanned
     *   "scanning" — in progress
     *   "clean"    — passed CDR; reconstructed file is in Downloads
     *   "modified" — CDR removed active content; cleaned copy is in Downloads
     *   "blocked"  — CDR refused to reconstruct (severe match)
     *   "error"    — pipeline failure */
    public final String cdrState;

    /** Human-readable summary of what CDR found, "" if not yet scanned. */
    public final String cdrSummary;

    public QuarantinedFile(String quarantineId,
                           String originalName,
                           String sourcePackage,
                           String sourceUrl,
                           String mimeType,
                           String sha256,
                           long sizeBytes,
                           long quarantinedAtMs,
                           String cdrState,
                           String cdrSummary) {
        this.quarantineId    = nz(quarantineId);
        this.originalName    = nz(originalName);
        this.sourcePackage   = nz(sourcePackage);
        this.sourceUrl       = nz(sourceUrl);
        this.mimeType        = nz(mimeType);
        this.sha256          = nz(sha256);
        this.sizeBytes       = sizeBytes;
        this.quarantinedAtMs = quarantinedAtMs;
        this.cdrState        = nz(cdrState);
        this.cdrSummary      = nz(cdrSummary);
    }

    private static String nz(String s) { return s == null ? "" : s; }

    private QuarantinedFile(Parcel in) {
        this.quarantineId    = in.readString();
        this.originalName    = in.readString();
        this.sourcePackage   = in.readString();
        this.sourceUrl       = in.readString();
        this.mimeType        = in.readString();
        this.sha256          = in.readString();
        this.sizeBytes       = in.readLong();
        this.quarantinedAtMs = in.readLong();
        this.cdrState        = in.readString();
        this.cdrSummary      = in.readString();
    }

    @Override public void writeToParcel(Parcel o, int f) {
        o.writeString(quarantineId);
        o.writeString(originalName);
        o.writeString(sourcePackage);
        o.writeString(sourceUrl);
        o.writeString(mimeType);
        o.writeString(sha256);
        o.writeLong(sizeBytes);
        o.writeLong(quarantinedAtMs);
        o.writeString(cdrState);
        o.writeString(cdrSummary);
    }

    @Override public int describeContents() { return 0; }

    public static final Parcelable.Creator<QuarantinedFile> CREATOR =
            new Parcelable.Creator<QuarantinedFile>() {
        @Override public QuarantinedFile createFromParcel(Parcel in) { return new QuarantinedFile(in); }
        @Override public QuarantinedFile[] newArray(int n) { return new QuarantinedFile[n]; }
    };
}
