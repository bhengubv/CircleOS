#!/usr/bin/env python3
# WP-12: pin apps to the dock (persisted). Long-press grid -> Pin, dock -> Unpin.
import sys

F = "src/com/circleos/launcher/CircleLauncherActivity.java"
s = open(F, encoding="utf-8").read()
orig = s
reps = []

# E1 - dock order: pinned first, then DOCK_CANDIDATES
reps.append((
    "        // Determine dock apps (first 5 from DOCK_CANDIDATES that are installed)\n"
    "        final Set<String> dockedPkgs = new LinkedHashSet<>();\n"
    "        int dockIdx = 0;\n"
    "        for (String candidate : DOCK_CANDIDATES) {",
    "        // Determine dock apps: pinned first (WP-12), then DOCK_CANDIDATES\n"
    "        final Set<String> dockedPkgs = new LinkedHashSet<>();\n"
    "        int dockIdx = 0;\n"
    "        final List<String> dockOrder = new ArrayList<>(loadPinned());\n"
    "        for (String c : DOCK_CANDIDATES) dockOrder.add(c);\n"
    "        for (String candidate : dockOrder) {"
))

# E2 - dock icon long-press -> unpin
reps.append((
    "                final int idx = i;\n"
    "                mDockIcons[i].setOnClickListener(v -> launchApp(mDockApps[idx]));",
    "                final int idx = i;\n"
    "                mDockIcons[i].setOnClickListener(v -> launchApp(mDockApps[idx]));\n"
    "                mDockIcons[i].setOnLongClickListener(v -> {\n"
    "                    ResolveInfo di = mDockApps[idx];\n"
    "                    if (di == null) return false;\n"
    "                    final String pkg = di.activityInfo.packageName;\n"
    "                    new android.app.AlertDialog.Builder(CircleLauncherActivity.this)\n"
    "                            .setTitle(di.loadLabel(pm))\n"
    "                            .setItems(new CharSequence[]{\"Unpin from dock\"},\n"
    "                                    (d, w) -> unpinFromDock(pkg))\n"
    "                            .show();\n"
    "                    return true;\n"
    "                });"
))

# E3 - grid long-press -> pin
reps.append((
    "        mAppGrid.setOnItemClickListener((parent, view, position, id) ->\n"
    "                launchApp((ResolveInfo) parent.getItemAtPosition(position)));",
    "        mAppGrid.setOnItemClickListener((parent, view, position, id) ->\n"
    "                launchApp((ResolveInfo) parent.getItemAtPosition(position)));\n"
    "        mAppGrid.setOnItemLongClickListener((parent, view, position, id) -> {\n"
    "            ResolveInfo gi = (ResolveInfo) parent.getItemAtPosition(position);\n"
    "            if (gi == null) return false;\n"
    "            final String pkg = gi.activityInfo.packageName;\n"
    "            new android.app.AlertDialog.Builder(CircleLauncherActivity.this)\n"
    "                    .setTitle(gi.loadLabel(getPackageManager()))\n"
    "                    .setItems(new CharSequence[]{\"Pin to dock\"},\n"
    "                            (d, w) -> pinToDock(pkg))\n"
    "                    .show();\n"
    "            return true;\n"
    "        });"
))

# E4 - pin/unpin helpers before launchApp
reps.append((
    "    private void launchApp(ResolveInfo ri) {",
    "    // WP-12: pin apps to the dock, persisted in SharedPreferences.\n"
    "    private java.util.List<String> loadPinned() {\n"
    "        String s = getSharedPreferences(\"circle_launcher\", MODE_PRIVATE)\n"
    "                .getString(\"pinned_dock\", \"\");\n"
    "        java.util.List<String> out = new ArrayList<>();\n"
    "        if (!s.isEmpty()) {\n"
    "            for (String p : s.split(\",\")) if (!p.isEmpty()) out.add(p);\n"
    "        }\n"
    "        return out;\n"
    "    }\n"
    "\n"
    "    private void savePinned(java.util.List<String> pinned) {\n"
    "        getSharedPreferences(\"circle_launcher\", MODE_PRIVATE).edit()\n"
    "                .putString(\"pinned_dock\", String.join(\",\", pinned)).apply();\n"
    "    }\n"
    "\n"
    "    private void pinToDock(String pkg) {\n"
    "        java.util.List<String> p = loadPinned();\n"
    "        p.remove(pkg);\n"
    "        p.add(0, pkg);\n"
    "        while (p.size() > DOCK_SIZE) p.remove(p.size() - 1);\n"
    "        savePinned(p);\n"
    "        loadApps();\n"
    "    }\n"
    "\n"
    "    private void unpinFromDock(String pkg) {\n"
    "        java.util.List<String> p = loadPinned();\n"
    "        if (p.remove(pkg)) {\n"
    "            savePinned(p);\n"
    "            loadApps();\n"
    "        }\n"
    "    }\n"
    "\n"
    "    private void launchApp(ResolveInfo ri) {"
))

ok = True
for i, (a, b) in enumerate(reps, 1):
    n = s.count(a)
    if n != 1:
        print("E%d: anchor count=%d (expected 1) - FAIL" % (i, n))
        ok = False
        continue
    s = s.replace(a, b, 1)
    print("E%d: applied" % i)

if ok and s != orig:
    open(F, "w", encoding="utf-8").write(s)
    print("WROTE " + F)
else:
    print("NOT WRITTEN - anchor mismatch")
    sys.exit(1)
