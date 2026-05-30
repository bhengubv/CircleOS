/*
 * Copyright (C) 2026 The Other Bhengu (PTY) Ltd t/a The Geek Network.
 *
 * One SDPKT transaction, either settled, in flight, or pending in the
 * offline queue.
 */

package com.circleos.sdpkt;

import android.os.Parcel;
import android.os.Parcelable;

public final class OfflineTransaction implements Parcelable {

    /** UUID hex (no dashes). Stable across boots and reconciliations. */
    public final String txId;

    /** ed25519 fingerprint of the sender (always the local wallet on send). */
    public final String fromWalletId;

    /** ed25519 fingerprint of the recipient. */
    public final String toWalletId;

    /** Amount in smallest unit of the wallet's currency. Always positive;
     *  direction implied by from/to. */
    public final long amountMinor;

    /** Free-form memo, possibly empty. Max 64 chars enforced at send. */
    public final String memo;

    /** Unix ms when the user initiated the transaction. */
    public final long createdAtMs;

    /** Unix ms when the central ledger acknowledged settlement, or 0
     *  if still pending. */
    public final long settledAtMs;

    /** Transport: "online" | "nfc" | "mesh" | "offline_queue" */
    public final String channel;

    /** State machine: "pending" | "signed" | "in_flight" | "settled"
     *  | "rejected" | "expired" */
    public final String state;

    /** If state == "rejected" or "expired", a short human reason; else "". */
    public final String failureReason;

    public OfflineTransaction(String txId,
                              String fromWalletId,
                              String toWalletId,
                              long amountMinor,
                              String memo,
                              long createdAtMs,
                              long settledAtMs,
                              String channel,
                              String state,
                              String failureReason) {
        this.txId          = nz(txId);
        this.fromWalletId  = nz(fromWalletId);
        this.toWalletId    = nz(toWalletId);
        this.amountMinor   = amountMinor;
        this.memo          = nz(memo);
        this.createdAtMs   = createdAtMs;
        this.settledAtMs   = settledAtMs;
        this.channel       = nz(channel);
        this.state         = nz(state);
        this.failureReason = nz(failureReason);
    }

    private static String nz(String s) { return s == null ? "" : s; }

    private OfflineTransaction(Parcel in) {
        this.txId          = in.readString();
        this.fromWalletId  = in.readString();
        this.toWalletId    = in.readString();
        this.amountMinor   = in.readLong();
        this.memo          = in.readString();
        this.createdAtMs   = in.readLong();
        this.settledAtMs   = in.readLong();
        this.channel       = in.readString();
        this.state         = in.readString();
        this.failureReason = in.readString();
    }

    @Override public void writeToParcel(Parcel o, int f) {
        o.writeString(txId);
        o.writeString(fromWalletId);
        o.writeString(toWalletId);
        o.writeLong(amountMinor);
        o.writeString(memo);
        o.writeLong(createdAtMs);
        o.writeLong(settledAtMs);
        o.writeString(channel);
        o.writeString(state);
        o.writeString(failureReason);
    }

    @Override public int describeContents() { return 0; }

    public static final Parcelable.Creator<OfflineTransaction> CREATOR =
            new Parcelable.Creator<OfflineTransaction>() {
        @Override public OfflineTransaction createFromParcel(Parcel in) { return new OfflineTransaction(in); }
        @Override public OfflineTransaction[] newArray(int n) { return new OfflineTransaction[n]; }
    };
}
