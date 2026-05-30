/*
 * Copyright (C) 2026 The Other Bhengu (PTY) Ltd t/a The Geek Network.
 *
 * Cheap snapshot of wallet state. Status UIs poll this.
 */

package com.circleos.sdpkt;

import android.os.Parcel;
import android.os.Parcelable;

public final class WalletInfo implements Parcelable {

    /** ed25519 fingerprint, hex (64 chars). */
    public final String walletId;

    /** ISO 4217 currency code, e.g. "ZAR" / "USD" / "INR". */
    public final String currency;

    /** Balance in smallest unit (cents for ZAR/USD, paise for INR). */
    public final long balanceMinor;

    /** Per-device daily send cap in the same unit. */
    public final long dailyCapMinor;

    /** Spent against the cap so far today, in the same unit. */
    public final long spentTodayMinor;

    /** Unix ms of the last successful reconcile with the central ledger. */
    public final long lastReconcileMs;

    /** Count of transactions pending in the offline queue. */
    public final int pendingOfflineTxCount;

    /** True if the wallet is locked (requires lock-screen auth to spend). */
    public final boolean locked;

    public WalletInfo(String walletId,
                      String currency,
                      long balanceMinor,
                      long dailyCapMinor,
                      long spentTodayMinor,
                      long lastReconcileMs,
                      int pendingOfflineTxCount,
                      boolean locked) {
        this.walletId              = nz(walletId);
        this.currency              = nz(currency);
        this.balanceMinor          = balanceMinor;
        this.dailyCapMinor         = dailyCapMinor;
        this.spentTodayMinor       = spentTodayMinor;
        this.lastReconcileMs       = lastReconcileMs;
        this.pendingOfflineTxCount = pendingOfflineTxCount;
        this.locked                = locked;
    }

    private static String nz(String s) { return s == null ? "" : s; }

    private WalletInfo(Parcel in) {
        this.walletId              = in.readString();
        this.currency              = in.readString();
        this.balanceMinor          = in.readLong();
        this.dailyCapMinor         = in.readLong();
        this.spentTodayMinor       = in.readLong();
        this.lastReconcileMs       = in.readLong();
        this.pendingOfflineTxCount = in.readInt();
        this.locked                = in.readInt() != 0;
    }

    @Override public void writeToParcel(Parcel o, int f) {
        o.writeString(walletId);
        o.writeString(currency);
        o.writeLong(balanceMinor);
        o.writeLong(dailyCapMinor);
        o.writeLong(spentTodayMinor);
        o.writeLong(lastReconcileMs);
        o.writeInt(pendingOfflineTxCount);
        o.writeInt(locked ? 1 : 0);
    }

    @Override public int describeContents() { return 0; }

    public static final Parcelable.Creator<WalletInfo> CREATOR =
            new Parcelable.Creator<WalletInfo>() {
        @Override public WalletInfo createFromParcel(Parcel in) { return new WalletInfo(in); }
        @Override public WalletInfo[] newArray(int n) { return new WalletInfo[n]; }
    };
}
