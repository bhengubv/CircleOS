/*
 * Listener callback for ICirclePersonalityManager#subscribe.
 *
 * oneway: the engine fires-and-forgets. Listeners must not block the
 * binder thread; if real UI work is needed, post to a handler.
 */

package za.co.circleos.personality;

oneway interface IPersonalityChangeListener {

    /**
     * Fired whenever the active mode changes.
     *
     * @param oldModeId  the mode that was active, or "" on first activation
     * @param newModeId  the mode now active
     * @param reason     "user", "schedule", "auto-revert", "tier-change"
     */
    void onModeChanged(String oldModeId, String newModeId, String reason);
}
