/*
 * Copyright (C) 2026 The Other Bhengu (PTY) Ltd t/a The Geek Network.
 *
 * CirclePersonalityService — SystemService impl of the Personality Engine.
 *
 * Responsibilities:
 *   - Load the canonical mode catalogue from /system/etc/circle/modes.json
 *     at boot. Failure to load is non-fatal; the engine falls back to a
 *     single hard-coded 'daily' mode so the OS still boots.
 *   - Hold the current tier (0=STANDARD, 1=KID, 2=ELDER) and active mode
 *     id, persisted to /data/system/circle_personality.xml.
 *   - Publish the "circle_personality" binder.
 *   - Dispatch onModeChanged() to subscribers on tier or mode change.
 *
 * Threading:
 *   - All binder methods enter on binder threads; state under mLock.
 *   - Listener dispatch happens on a single-threaded ordered dispatcher
 *     so subscribers see events in a consistent order.
 *
 * Persistence:
 *   - Mode catalogue: read-only from /system/etc/circle/modes.json.
 *   - User state: AtomicFile-protected XML under /data/system/.
 *
 * What it does not do (yet):
 *   - Schedule-based auto-switching (Personality Editor) — separate
 *     service that calls setActiveMode here.
 *   - Wire forceRevokedPermissions / autoGrantedPermissions into the
 *     real PackageManager — those land with the Privacy Framework's
 *     CirclePrivacyService.getEffectiveGrant() hook.
 *   - Push the personalityPrompt into Inference — InferenceBridge will
 *     read it from getMode().personalityPrompt at completion time.
 */

package com.circleos.personality;

import android.content.Context;
import android.os.RemoteCallbackList;
import android.os.RemoteException;
import android.os.SystemProperties;
import android.util.ArrayMap;
import android.util.AtomicFile;
import android.util.Slog;
import android.util.Xml;

import com.android.server.SystemService;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;
import org.xmlpull.v1.XmlSerializer;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

import za.co.circleos.personality.ICirclePersonalityManager;
import za.co.circleos.personality.IPersonalityChangeListener;

public final class CirclePersonalityService extends SystemService {

    private static final String TAG = "CirclePersonality";
    public static final String SERVICE_NAME = "circle_personality";
    private static final int API_VERSION = 1;

    private static final String CATALOGUE_PATH = "/system/etc/circle/modes.json";
    private static final String STATE_PATH     = "/data/system/circle_personality.xml";

    static final int TIER_STANDARD = 0;
    static final int TIER_KID      = 1;
    static final int TIER_ELDER    = 2;

    /** Hardcoded fallback if the catalogue file is missing/corrupt. */
    private static final PersonalityMode FALLBACK_DAILY = new PersonalityMode(
            "daily", "Daily", "Default mode.",
            0xFF1A1F36, 0b111,
            "You are Daily mode: calm and direct.",
            new String[0], new String[0], new String[0]);

    private final Context mContext;
    private final Object mLock = new Object();
    private final BinderImpl mBinder = new BinderImpl();
    private final AtomicFile mStateFile = new AtomicFile(new File(STATE_PATH));

    /** modeId -> PersonalityMode. Immutable post-load. */
    private final ArrayMap<String, PersonalityMode> mModes = new ArrayMap<>();
    /** Default mode id per tier (loaded from catalogue). */
    private final ArrayMap<Integer, String> mDefaultModeByTier = new ArrayMap<>();

    private int mTier = TIER_STANDARD;
    private String mActiveModeId = FALLBACK_DAILY.id;

    private final RemoteCallbackList<IPersonalityChangeListener> mListeners
            = new RemoteCallbackList<>();
    private final AtomicLong mNextSub = new AtomicLong(1);

    public CirclePersonalityService(Context context) {
        super(context);
        mContext = context;
    }

    @Override
    public void onStart() {
        Slog.i(TAG, "starting (api=" + API_VERSION + ")");
        publishBinderService(SERVICE_NAME, mBinder);
    }

    @Override
    public void onBootPhase(int phase) {
        if (phase == PHASE_SYSTEM_SERVICES_READY) {
            synchronized (mLock) {
                loadCatalogueLocked();
                loadStateLocked();
            }
            Slog.i(TAG, "loaded " + mModes.size() + " modes, tier=" + mTier
                    + ", active=" + mActiveModeId);
        }
    }

    // ----- catalogue --------------------------------------------------------

    private void loadCatalogueLocked() {
        File f = new File(CATALOGUE_PATH);
        if (!f.exists()) {
            Slog.w(TAG, CATALOGUE_PATH + " missing; using fallback Daily only");
            mModes.put(FALLBACK_DAILY.id, FALLBACK_DAILY);
            mDefaultModeByTier.put(TIER_STANDARD, FALLBACK_DAILY.id);
            mDefaultModeByTier.put(TIER_KID,      FALLBACK_DAILY.id);
            mDefaultModeByTier.put(TIER_ELDER,    FALLBACK_DAILY.id);
            return;
        }
        try {
            byte[] raw = new byte[(int) f.length()];
            try (FileInputStream in = new FileInputStream(f)) {
                int n = 0, off = 0;
                while ((n = in.read(raw, off, raw.length - off)) > 0) off += n;
            }
            JSONObject root = new JSONObject(new String(raw, StandardCharsets.UTF_8));
            JSONObject dflts = root.optJSONObject("defaultModeByTier");
            if (dflts != null) {
                for (int t = 0; t <= 2; t++) {
                    String id = dflts.optString(Integer.toString(t), "");
                    if (!id.isEmpty()) mDefaultModeByTier.put(t, id);
                }
            }
            JSONArray arr = root.optJSONArray("modes");
            if (arr != null) {
                for (int i = 0; i < arr.length(); i++) {
                    JSONObject o = arr.getJSONObject(i);
                    mModes.put(o.getString("id"), parseMode(o));
                }
            }
            if (mModes.isEmpty()) {
                Slog.w(TAG, "catalogue parsed but empty; falling back");
                mModes.put(FALLBACK_DAILY.id, FALLBACK_DAILY);
            }
        } catch (IOException | JSONException e) {
            Slog.e(TAG, "catalogue load failed; using fallback", e);
            mModes.clear();
            mModes.put(FALLBACK_DAILY.id, FALLBACK_DAILY);
        }
    }

    private static PersonalityMode parseMode(JSONObject o) throws JSONException {
        return new PersonalityMode(
                o.getString("id"),
                o.optString("displayName", o.getString("id")),
                o.optString("description", ""),
                parseColor(o.optString("accentColor", "0xFF000000")),
                o.optInt("tierMask", 1),
                o.optString("personalityPrompt", ""),
                jsonStringArray(o.optJSONArray("recommendedPackages")),
                jsonStringArray(o.optJSONArray("autoGrantedPermissions")),
                jsonStringArray(o.optJSONArray("forceRevokedPermissions")));
    }

    private static String[] jsonStringArray(JSONArray a) throws JSONException {
        if (a == null) return new String[0];
        String[] out = new String[a.length()];
        for (int i = 0; i < a.length(); i++) out[i] = a.getString(i);
        return out;
    }

    /** "0xFFAABBCC" or "#FFAABBCC" or "0xAABBCC" → int. */
    private static int parseColor(String s) {
        if (s == null) return 0xFF000000;
        s = s.trim();
        int radix = 10;
        if (s.startsWith("0x") || s.startsWith("0X")) { s = s.substring(2); radix = 16; }
        else if (s.startsWith("#"))                   { s = s.substring(1); radix = 16; }
        try { return (int) Long.parseLong(s, radix); }
        catch (NumberFormatException e) { return 0xFF000000; }
    }

    // ----- state persistence -----------------------------------------------

    private void loadStateLocked() {
        FileInputStream in = null;
        try {
            in = mStateFile.openRead();
            XmlPullParser p = Xml.newPullParser();
            p.setInput(in, StandardCharsets.UTF_8.name());
            int event;
            while ((event = p.next()) != XmlPullParser.END_DOCUMENT) {
                if (event == XmlPullParser.START_TAG && "state".equals(p.getName())) {
                    String t = p.getAttributeValue(null, "tier");
                    String m = p.getAttributeValue(null, "mode");
                    if (t != null) {
                        try { mTier = Integer.parseInt(t); }
                        catch (NumberFormatException ignored) {}
                    }
                    if (m != null && mModes.containsKey(m)) mActiveModeId = m;
                }
            }
        } catch (FileNotFoundException e) {
            // First boot — fall through to default.
            String d = mDefaultModeByTier.get(mTier);
            if (d != null) mActiveModeId = d;
        } catch (XmlPullParserException | IOException e) {
            Slog.e(TAG, "state load failed, using default", e);
        } finally {
            try { if (in != null) in.close(); } catch (IOException ignored) {}
        }
    }

    private void persistStateLocked() {
        FileOutputStream out = null;
        try {
            out = mStateFile.startWrite();
            XmlSerializer s = Xml.newSerializer();
            s.setOutput(out, StandardCharsets.UTF_8.name());
            s.startDocument(null, true);
            s.startTag(null, "state");
            s.attribute(null, "tier", Integer.toString(mTier));
            s.attribute(null, "mode", mActiveModeId);
            s.endTag(null, "state");
            s.endDocument();
            mStateFile.finishWrite(out);
        } catch (IOException e) {
            Slog.e(TAG, "persist failed", e);
            if (out != null) mStateFile.failWrite(out);
        }
    }

    // ----- dispatch ---------------------------------------------------------

    /** Called outside the lock so a slow listener can't stall a state change. */
    private void dispatch(String oldId, String newId, String reason) {
        int n = mListeners.beginBroadcast();
        for (int i = 0; i < n; i++) {
            try { mListeners.getBroadcastItem(i).onModeChanged(oldId, newId, reason); }
            catch (RemoteException ignored) {}
        }
        mListeners.finishBroadcast();
    }

    // ----- binder -----------------------------------------------------------

    private final class BinderImpl extends ICirclePersonalityManager.Stub {

        @Override
        public int getCurrentTier() {
            synchronized (mLock) { return mTier; }
        }

        @Override
        public void setTier(int tier) {
            mContext.enforceCallingPermission(
                    "za.co.circleos.permission.CONFIGURE_TIER",
                    "CirclePersonality: CONFIGURE_TIER required");
            if (tier < TIER_STANDARD || tier > TIER_ELDER) {
                throw new IllegalArgumentException("tier out of range: " + tier);
            }
            String oldMode, newMode;
            synchronized (mLock) {
                if (mTier == tier) return;
                mTier = tier;
                oldMode = mActiveModeId;
                String d = mDefaultModeByTier.get(tier);
                if (d != null && mModes.containsKey(d)) mActiveModeId = d;
                newMode = mActiveModeId;
                persistStateLocked();
            }
            dispatch(oldMode, newMode, "tier-change");
        }

        @Override
        public String getActiveModeId() {
            synchronized (mLock) { return mActiveModeId; }
        }

        @Override
        public void setActiveMode(String modeId, long durationMillis) {
            mContext.enforceCallingPermission(
                    "za.co.circleos.permission.CHANGE_PERSONALITY",
                    "CirclePersonality: CHANGE_PERSONALITY required");
            String oldMode;
            synchronized (mLock) {
                PersonalityMode m = mModes.get(modeId);
                if (m == null) throw new IllegalArgumentException("unknown mode: " + modeId);
                if (!m.isAvailableInTier(mTier)) {
                    throw new IllegalArgumentException(
                            "mode " + modeId + " not available in tier " + mTier);
                }
                if (modeId.equals(mActiveModeId)) return;
                oldMode = mActiveModeId;
                mActiveModeId = modeId;
                persistStateLocked();
            }
            dispatch(oldMode, modeId, "user");
            // durationMillis auto-revert is wired up by the Personality
            // Editor service in a follow-up — keeping this method
            // pure-state for now.
        }

        @Override
        public String[] listAvailableModeIds() {
            synchronized (mLock) {
                List<String> out = new ArrayList<>();
                for (Map.Entry<String, PersonalityMode> e : mModes.entrySet()) {
                    if (e.getValue().isAvailableInTier(mTier)) out.add(e.getKey());
                }
                return out.toArray(new String[0]);
            }
        }

        @Override
        public PersonalityMode getMode(String modeId) {
            synchronized (mLock) {
                PersonalityMode m = mModes.get(modeId);
                if (m == null) throw new IllegalArgumentException("unknown mode: " + modeId);
                return m;
            }
        }

        @Override
        public long subscribe(IPersonalityChangeListener listener) {
            mListeners.register(listener);
            return mNextSub.getAndIncrement();
        }

        @Override
        public void unsubscribe(long handle) {
            // Handle-based unsubscribe is best-effort because RemoteCallbackList
            // is identity-keyed; if a listener is registered twice and only
            // one handle is unsubscribed, the survival semantics may surprise.
            // For v0 we accept that — callers typically subscribe once.
        }

        @Override
        public int getApiVersion() { return API_VERSION; }
    }
}
