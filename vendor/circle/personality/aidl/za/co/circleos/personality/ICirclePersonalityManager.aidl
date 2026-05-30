/*
 * Copyright (C) 2026 The Other Bhengu (PTY) Ltd t/a The Geek Network.
 *
 * AIDL surface for the Circle Personality Engine.
 *
 * The engine is what makes CircleOS feel like *your* phone instead of a
 * generic Android. Each mode is a coherent bundle of:
 *
 *   - visual overlay (accent colour, wallpaper, icon tint)
 *   - default permission profile (which packages have which perms today)
 *   - recommended-app set (what the home / launcher surfaces first)
 *   - personality prompt template (the system prompt fed to the Inference
 *     Service when an app asks for an LLM completion in this mode)
 *
 * A mode is activated either explicitly by the user (toggling in
 * CircleSettings) or implicitly by a Personality Editor automation rule
 * (e.g. "weekdays 09:00-17:00 = Work").
 *
 * Tiers gate which modes are even *available*:
 *   STANDARD — full 20+ mode catalogue
 *   KID      — Daily / Student / Sleep only; no Inference access
 *   ELDER    — Daily / Calm / Emergency; large fonts default; voice-only nav
 *
 * Callers must hold za.co.circleos.permission.QUERY_PERSONALITY for
 * read methods; setActiveMode requires CHANGE_PERSONALITY; tier changes
 * require CONFIGURE_TIER (signature|privileged).
 */

package za.co.circleos.personality;

import za.co.circleos.personality.PersonalityMode;
import za.co.circleos.personality.IPersonalityChangeListener;

/** Binder published under SERVICE_NAME = "circle_personality". */
interface ICirclePersonalityManager {

    // ----- tier --------------------------------------------------------

    /** Current tier: 0 = STANDARD, 1 = KID, 2 = ELDER. */
    int getCurrentTier();

    /**
     * Change the user-experience tier. Sensitive — guarded by
     * CONFIGURE_TIER. Resets the active mode to that tier's default.
     */
    void setTier(int tier);

    // ----- modes -------------------------------------------------------

    /** Machine-readable id of the currently active mode, e.g. "daily". */
    String getActiveModeId();

    /**
     * Activate a mode by id. If durationMillis > 0, the engine reverts to
     * the prior mode automatically after the duration; if 0, the mode
     * persists until changed.
     *
     * Throws if modeId is not in the current tier's catalogue.
     */
    void setActiveMode(in String modeId, long durationMillis);

    /**
     * Ids of modes available in the current tier. Callers use this to
     * populate UI pickers.
     */
    String[] listAvailableModeIds();

    /**
     * Full metadata for a mode. Throws if modeId is not known to the
     * current tier.
     */
    PersonalityMode getMode(in String modeId);

    // ----- subscriptions ----------------------------------------------

    /**
     * Subscribe to mode change events. The listener receives a callback
     * each time setActiveMode is called (including auto-revert).
     *
     * @return subscription handle for unsubscribe
     */
    long subscribe(in IPersonalityChangeListener listener);

    void unsubscribe(long handle);

    // ----- versioning --------------------------------------------------

    /** API schema version. */
    int getApiVersion();
}
