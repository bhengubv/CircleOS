/*
 * Balance-change callback for ICircleSdpktManager#subscribeBalanceChanges.
 *
 * oneway — fire and forget. Listeners must return quickly.
 */

package za.co.circleos.sdpkt;

oneway interface IBalanceChangeListener {

    /**
     * Fired on any balance change: send, receive, settlement, refund.
     *
     * @param newBalanceCents  authoritative new balance after the change
     * @param deltaCents       signed change that triggered this event
     *                         (positive = inflow, negative = outflow)
     * @param reason           "send" | "receive" | "settlement" |
     *                         "refund" | "reconcile"
     */
    void onBalanceChanged(long newBalanceCents, long deltaCents, String reason);
}
