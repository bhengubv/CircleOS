#!/usr/bin/env python3
# Patch CircleLauncherActivity for Live Tiles v1: clock fields, findViewById,
# time-tick receiver, updateClock(), onPause(). Idempotent-safe: each anchor
# must appear exactly once or the patch refuses to write.
import sys

F = "src/com/circleos/launcher/CircleLauncherActivity.java"
s = open(F, encoding="utf-8").read()
orig = s

reps = []

# R1 - clock fields + time receiver
reps.append((
    "    private final ResolveInfo[] mDockApps = new ResolveInfo[DOCK_SIZE];",
    "    private final ResolveInfo[] mDockApps = new ResolveInfo[DOCK_SIZE];\n"
    "    private TextView mClockTime;\n"
    "    private TextView mClockDate;\n"
    "\n"
    "    /** Updates the live clock tile on every minute tick / time change. */\n"
    "    private final android.content.BroadcastReceiver mTimeReceiver =\n"
    "            new android.content.BroadcastReceiver() {\n"
    "        @Override public void onReceive(android.content.Context c, Intent i) { updateClock(); }\n"
    "    };"
))

# R2 - wire the clock tile views
reps.append((
    "= findViewById(R.id.app_grid);",
    "= findViewById(R.id.app_grid);\n"
    "        mClockTime = findViewById(R.id.clock_time);\n"
    "        mClockDate = findViewById(R.id.clock_date);"
))

# R3 - onResume + onPause + updateClock
reps.append((
    "    @Override\n"
    "    protected void onResume() {\n"
    "        super.onResume();\n"
    "        refreshPrivacyWidget();\n"
    "    }",
    "    @Override\n"
    "    protected void onResume() {\n"
    "        super.onResume();\n"
    "        refreshPrivacyWidget();\n"
    "        updateClock();\n"
    "        android.content.IntentFilter tf = new android.content.IntentFilter();\n"
    "        tf.addAction(Intent.ACTION_TIME_TICK);\n"
    "        tf.addAction(Intent.ACTION_TIME_CHANGED);\n"
    "        tf.addAction(Intent.ACTION_TIMEZONE_CHANGED);\n"
    "        registerReceiver(mTimeReceiver, tf);\n"
    "    }\n"
    "\n"
    "    @Override\n"
    "    protected void onPause() {\n"
    "        super.onPause();\n"
    "        try { unregisterReceiver(mTimeReceiver); } catch (Throwable ignored) {}\n"
    "    }\n"
    "\n"
    "    /** Live clock tile - time respects the user's 12/24h setting. */\n"
    "    private void updateClock() {\n"
    "        java.util.Date now = new java.util.Date();\n"
    "        if (mClockTime != null) {\n"
    "            mClockTime.setText(\n"
    "                    android.text.format.DateFormat.getTimeFormat(this).format(now));\n"
    "        }\n"
    "        if (mClockDate != null) {\n"
    "            mClockDate.setText(new java.text.SimpleDateFormat(\n"
    "                    \"EEEE, d MMMM\", java.util.Locale.getDefault()).format(now));\n"
    "        }\n"
    "    }"
))

ok = True
for i, (a, b) in enumerate(reps, 1):
    n = s.count(a)
    if n != 1:
        print("R%d: anchor count=%d (expected 1) - FAIL" % (i, n))
        ok = False
        continue
    s = s.replace(a, b, 1)
    print("R%d: applied" % i)

if ok and s != orig:
    open(F, "w", encoding="utf-8").write(s)
    print("WROTE " + F)
else:
    print("NOT WRITTEN - one or more anchors failed")
    sys.exit(1)
