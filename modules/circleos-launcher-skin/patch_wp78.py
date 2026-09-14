#!/usr/bin/env python3
# WP-78: sort the launcher app grid A->Z and add a SectionIndexer fast-scroll.
import sys

F = "src/com/circleos/launcher/CircleLauncherActivity.java"
s = open(F, encoding="utf-8").read()
orig = s
reps = []

# R1 - sort grid apps + pass label cache to adapter + enable fast scroll
reps.append((
    "        // Grid apps = all apps minus self minus docked\n"
    "        final List<ResolveInfo> gridApps = new ArrayList<>();\n"
    "        for (ResolveInfo ri : allApps) {\n"
    "            String pkg = ri.activityInfo.packageName;\n"
    "            if (getPackageName().equals(pkg)) continue;\n"
    "            if (dockedPkgs.contains(pkg)) continue;\n"
    "            gridApps.add(ri);\n"
    "        }\n"
    "\n"
    "        mAppGrid.setAdapter(new AppAdapter(gridApps, pm));\n"
    "        mAppGrid.setOnItemClickListener((parent, view, position, id) ->\n"
    "                launchApp((ResolveInfo) parent.getItemAtPosition(position)));",
    "        // Grid apps = all apps minus self minus docked, sorted A->Z by label\n"
    "        final List<ResolveInfo> gridApps = new ArrayList<>();\n"
    "        for (ResolveInfo ri : allApps) {\n"
    "            String pkg = ri.activityInfo.packageName;\n"
    "            if (getPackageName().equals(pkg)) continue;\n"
    "            if (dockedPkgs.contains(pkg)) continue;\n"
    "            gridApps.add(ri);\n"
    "        }\n"
    "        final java.util.Map<ResolveInfo, String> labels = new java.util.HashMap<>();\n"
    "        for (ResolveInfo ri : gridApps) labels.put(ri, String.valueOf(ri.loadLabel(pm)));\n"
    "        gridApps.sort((a, b) -> labels.get(a).compareToIgnoreCase(labels.get(b)));\n"
    "\n"
    "        mAppGrid.setAdapter(new AppAdapter(gridApps, pm, labels));\n"
    "        mAppGrid.setFastScrollEnabled(true);          // WP-78: alphabetical jump\n"
    "        mAppGrid.setOnItemClickListener((parent, view, position, id) ->\n"
    "                launchApp((ResolveInfo) parent.getItemAtPosition(position)));"
))

# R2 - AppAdapter gains a label cache + SectionIndexer (the A->Z jump)
reps.append((
    "    private final class AppAdapter extends BaseAdapter {\n"
    "        private final List<ResolveInfo> mApps;\n"
    "        private final PackageManager mPm;\n"
    "        private final int mIconPx;\n"
    "\n"
    "        AppAdapter(List<ResolveInfo> apps, PackageManager pm) {\n"
    "            mApps  = apps;\n"
    "            mPm    = pm;\n"
    "            mIconPx = dpToPx(ICON_SIZE_DP);\n"
    "        }\n"
    "\n"
    "        @Override public int getCount()              { return mApps.size(); }\n"
    "        @Override public ResolveInfo getItem(int p)  { return mApps.get(p); }\n"
    "        @Override public long getItemId(int p)       { return p; }\n"
    "\n"
    "        @Override\n"
    "        public View getView(int position, View convertView, ViewGroup parent) {\n"
    "            View row = convertView != null\n"
    "                    ? convertView\n"
    "                    : LayoutInflater.from(parent.getContext())\n"
    "                            .inflate(R.layout.app_grid_cell, parent, false);\n"
    "            ResolveInfo info = mApps.get(position);\n"
    "            ImageView icon = row.findViewById(R.id.app_icon);\n"
    "            icon.setImageDrawable(roundIcon(info.loadIcon(mPm), mIconPx));\n"
    "            ((TextView) row.findViewById(R.id.app_label))\n"
    "                    .setText(info.loadLabel(mPm));\n"
    "            return row;\n"
    "        }\n"
    "    }",
    "    private final class AppAdapter extends BaseAdapter\n"
    "            implements android.widget.SectionIndexer {\n"
    "        private final List<ResolveInfo> mApps;\n"
    "        private final PackageManager mPm;\n"
    "        private final int mIconPx;\n"
    "        private final java.util.Map<ResolveInfo, String> mLabels;\n"
    "        private final String[] mSections;\n"
    "\n"
    "        AppAdapter(List<ResolveInfo> apps, PackageManager pm,\n"
    "                   java.util.Map<ResolveInfo, String> labels) {\n"
    "            mApps   = apps;\n"
    "            mPm     = pm;\n"
    "            mLabels = labels;\n"
    "            mIconPx = dpToPx(ICON_SIZE_DP);\n"
    "            java.util.LinkedHashSet<String> secs = new java.util.LinkedHashSet<>();\n"
    "            for (ResolveInfo ri : apps) secs.add(sectionOf(ri));\n"
    "            mSections = secs.toArray(new String[0]);\n"
    "        }\n"
    "\n"
    "        private String sectionOf(ResolveInfo ri) {\n"
    "            String l = mLabels.get(ri);\n"
    "            if (l == null || l.isEmpty()) return \"#\";\n"
    "            char c = Character.toUpperCase(l.charAt(0));\n"
    "            return Character.isLetter(c) ? String.valueOf(c) : \"#\";\n"
    "        }\n"
    "\n"
    "        @Override public int getCount()              { return mApps.size(); }\n"
    "        @Override public ResolveInfo getItem(int p)  { return mApps.get(p); }\n"
    "        @Override public long getItemId(int p)       { return p; }\n"
    "\n"
    "        @Override public Object[] getSections()      { return mSections; }\n"
    "\n"
    "        @Override\n"
    "        public int getPositionForSection(int section) {\n"
    "            if (section < 0) section = 0;\n"
    "            if (section >= mSections.length) section = mSections.length - 1;\n"
    "            String want = mSections[section];\n"
    "            for (int i = 0; i < mApps.size(); i++) {\n"
    "                if (want.equals(sectionOf(mApps.get(i)))) return i;\n"
    "            }\n"
    "            return 0;\n"
    "        }\n"
    "\n"
    "        @Override\n"
    "        public int getSectionForPosition(int position) {\n"
    "            if (position < 0 || position >= mApps.size()) return 0;\n"
    "            String sec = sectionOf(mApps.get(position));\n"
    "            for (int i = 0; i < mSections.length; i++) {\n"
    "                if (mSections[i].equals(sec)) return i;\n"
    "            }\n"
    "            return 0;\n"
    "        }\n"
    "\n"
    "        @Override\n"
    "        public View getView(int position, View convertView, ViewGroup parent) {\n"
    "            View row = convertView != null\n"
    "                    ? convertView\n"
    "                    : LayoutInflater.from(parent.getContext())\n"
    "                            .inflate(R.layout.app_grid_cell, parent, false);\n"
    "            ResolveInfo info = mApps.get(position);\n"
    "            ImageView icon = row.findViewById(R.id.app_icon);\n"
    "            icon.setImageDrawable(roundIcon(info.loadIcon(mPm), mIconPx));\n"
    "            ((TextView) row.findViewById(R.id.app_label))\n"
    "                    .setText(mLabels.get(info));\n"
    "            return row;\n"
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
    print("NOT WRITTEN - anchor mismatch")
    sys.exit(1)
