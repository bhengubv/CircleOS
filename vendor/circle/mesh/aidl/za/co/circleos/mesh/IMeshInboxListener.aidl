/*
 * Inbox callback for ICircleMeshManager#subscribeInbox.
 *
 * oneway — the mesh service fires-and-forgets. Listeners must return
 * quickly; if real work is needed, post to a worker thread.
 */

package za.co.circleos.mesh;

oneway interface IMeshInboxListener {

    /**
     * A message addressed to this node (or broadcast on a subscribed
     * topic) was received and de-duplicated.
     *
     * @param senderNodeId  Ed25519 fingerprint of the originator
     * @param topic         topic the message was sent on
     * @param payload       opaque payload bytes (already
     *                      transport-layer verified for sender signature)
     * @param messageId     128-bit hex id (matches the sender's
     *                      sendMessage return value)
     */
    void onMessage(String senderNodeId,
                   String topic,
                   in byte[] payload,
                   String messageId);
}
