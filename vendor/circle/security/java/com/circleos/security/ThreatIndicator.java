/*
 * Copyright (C) 2026 The Other Bhengu (PTY) Ltd t/a The Geek Network.
 *
 * One indicator from the Data Acuity threat feed.
 *
 * Indicators can be domains, IPs, file hashes (sha256), URL prefixes, or
 * MITRE ATT&CK TTP identifiers. The {@code kind} field disambiguates;
 * {@code value} carries the indicator itself.
 */

package com.circleos.security;

import android.os.Parcel;
import android.os.Parcelable;

public final class ThreatIndicator implements Parcelable {

    /** "domain", "ip", "sha256", "url", "ttp" (MITRE) */
    public final String kind;

    /** The indicator itself. */
    public final String value;

    /** Campaign id this indicator belongs to (Data Acuity-assigned), or "". */
    public final String campaignId;

    /** Severity 0..100 — derived from feed confidence + campaign weight. */
    public final int severity;

    /** Unix ms of first observation in the feed. */
    public final long firstSeenMs;

    /** Unix ms of most recent observation in the feed. */
    public final long lastSeenMs;

    /** Short tag — "phishing", "c2", "exfil", "dropper", "scam-call", … */
    public final String category;

    /** Free-form description / context, "" if none. */
    public final String summary;

    public ThreatIndicator(String kind,
                           String value,
                           String campaignId,
                           int severity,
                           long firstSeenMs,
                           long lastSeenMs,
                           String category,
                           String summary) {
        this.kind        = nz(kind);
        this.value       = nz(value);
        this.campaignId  = nz(campaignId);
        this.severity    = severity;
        this.firstSeenMs = firstSeenMs;
        this.lastSeenMs  = lastSeenMs;
        this.category    = nz(category);
        this.summary     = nz(summary);
    }

    private static String nz(String s) { return s == null ? "" : s; }

    private ThreatIndicator(Parcel in) {
        this.kind        = in.readString();
        this.value       = in.readString();
        this.campaignId  = in.readString();
        this.severity    = in.readInt();
        this.firstSeenMs = in.readLong();
        this.lastSeenMs  = in.readLong();
        this.category    = in.readString();
        this.summary     = in.readString();
    }

    @Override public void writeToParcel(Parcel o, int f) {
        o.writeString(kind);
        o.writeString(value);
        o.writeString(campaignId);
        o.writeInt(severity);
        o.writeLong(firstSeenMs);
        o.writeLong(lastSeenMs);
        o.writeString(category);
        o.writeString(summary);
    }

    @Override public int describeContents() { return 0; }

    public static final Parcelable.Creator<ThreatIndicator> CREATOR =
            new Parcelable.Creator<ThreatIndicator>() {
        @Override public ThreatIndicator createFromParcel(Parcel in) { return new ThreatIndicator(in); }
        @Override public ThreatIndicator[] newArray(int n) { return new ThreatIndicator[n]; }
    };
}
