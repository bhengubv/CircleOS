#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Wire ShongololoWalletService to use the unit-tested WalletMath (money state +
# arithmetic) and WalletFrame (offer canonicalization). Ordered edits so the
# original anchors stay valid; the global field-rename runs last.
import sys
F = "frameworks/base/services/core/java/com/circleos/server/wallet/ShongololoWalletService.java"
s = open(F, encoding="utf-8").read()
if "mMath" in s:
    print("already wired"); sys.exit(0)

edits = []

# E1 — beginNfcSession limit checks -> WalletMath.checkSend (keep event severity mapping)
edits.append((
'                long perTap = req.lockScreenMode ? LOCK_PER_TAP_CENTS : BASE_PER_TAP_CENTS;\n'
'                if (req.amountCents > perTap) { logEvent(ProtectionEvent.TYPE_RATE_LIMIT,\n'
'                        ProtectionEvent.SEVERITY_BLOCK, "over per-tap limit", req.amountCents); return null; }\n'
'                if (req.amountCents > Math.max(0, BASE_DAILY_CENTS - mDailySpentCents)) {\n'
'                    logEvent(ProtectionEvent.TYPE_RATE_LIMIT, ProtectionEvent.SEVERITY_BLOCK,\n'
'                            "over daily limit", req.amountCents); return null; }\n'
'                if (req.amountCents > mAvailableCents) { logEvent(ProtectionEvent.TYPE_AMOUNT_OUTLIER,\n'
'                        ProtectionEvent.SEVERITY_WARN, "insufficient funds", req.amountCents); return null; }',
'                String block = mMath.checkSend(req.amountCents, req.lockScreenMode, nowMs());\n'
'                if (block != null) {\n'
'                    boolean funds = "insufficient funds".equals(block);\n'
'                    logEvent(funds ? ProtectionEvent.TYPE_AMOUNT_OUTLIER : ProtectionEvent.TYPE_RATE_LIMIT,\n'
'                            funds ? ProtectionEvent.SEVERITY_WARN : ProtectionEvent.SEVERITY_BLOCK,\n'
'                            block, req.amountCents);\n'
'                    return null;\n'
'                }'))

# E2 — finalizeSend inline math -> WalletMath.finalizeSend
edits.append((
'            mAvailableCents = Math.max(0, mAvailableCents - s.amountCents);\n'
'            mPendingOutCents += s.amountCents;\n'
'            mDailySpentCents += s.amountCents;',
'            mMath.finalizeSend(s.amountCents, nowMs());'))

# E3 — accept incoming credit -> WalletMath.acceptRecv
edits.append((
'                mPendingInCents += r.amountCents;',
'                mMath.acceptRecv(r.amountCents);'))

# E4 — settlement -> WalletMath.settleSend / settleRecv
edits.append((
'                mPendingOutCents = Math.max(0, mPendingOutCents - amt);\n'
'            } else if (t.optInt("type") == ShongololoTransaction.TYPE_RECV) {\n'
'                mPendingInCents = Math.max(0, mPendingInCents - amt);\n'
'                mAvailableCents += amt;',
'                mMath.settleSend(amt);\n'
'            } else if (t.optInt("type") == ShongololoTransaction.TYPE_RECV) {\n'
'                mMath.settleRecv(amt);'))

# E5 — getDailyRemaining -> WalletMath.dailyRemaining
edits.append((
'                return Math.max(0, BASE_DAILY_CENTS - mDailySpentCents);',
'                return mMath.dailyRemaining();'))

# E6 — offerBytes -> WalletFrame.offerBytes
edits.append((
'    private byte[] offerBytes(String rsid, long amt, String memo) {\n'
'        return ("SDPKT|" + rsid + "|" + amt + "|" + (memo == null ? "" : memo))\n'
'                .getBytes(StandardCharsets.UTF_8);\n'
'    }',
'    private byte[] offerBytes(String rsid, long amt, String memo) {\n'
'        return WalletFrame.offerBytes(rsid, amt, memo);\n'
'    }'))

# E7 — rolloverDay -> WalletMath.rolloverDay
edits.append((
'    private void rolloverDay() {\n'
'        long day = nowMs() / DAY_MS;\n'
'        if (day != mDailyEpochDay) { mDailyEpochDay = day; mDailySpentCents = 0; }\n'
'    }',
'    private void rolloverDay() {\n'
'        mMath.rolloverDay(nowMs());\n'
'    }'))

# E8 — replace the five money fields with a single WalletMath holder
edits.append((
'    private long    mAvailableCents;\n'
'    private long    mPendingInCents;\n'
'    private long    mPendingOutCents;\n'
'    private long    mDailySpentCents;\n'
'    private long    mDailyEpochDay;',
'    /** Money state + arithmetic, unit-tested in WalletMathTest (21/21). */\n'
'    private final WalletMath mMath =\n'
'            new WalletMath(BASE_PER_TAP_CENTS, LOCK_PER_TAP_CENTS, BASE_DAILY_CENTS);'))

for i, (old, new) in enumerate(edits, 1):
    if old not in s:
        print("FAIL: edit E%d anchor not found" % i); sys.exit(1)
    s = s.replace(old, new, 1)

# E9 — global rename of any remaining field reads (getBalance, load/save, analytics, etc.)
for ident, repl in (("mAvailableCents", "mMath.available"),
                     ("mPendingInCents", "mMath.pendingIn"),
                     ("mPendingOutCents", "mMath.pendingOut"),
                     ("mDailySpentCents", "mMath.dailySpent"),
                     ("mDailyEpochDay", "mMath.dailyEpochDay")):
    s = s.replace(ident, repl)

open(F, "w", encoding="utf-8").write(s)
print("wallet service wired to WalletMath + WalletFrame")
