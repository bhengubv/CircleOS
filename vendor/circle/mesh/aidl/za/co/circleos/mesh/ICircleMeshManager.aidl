/*
 * Copyright (C) 2026 The Other Bhengu (PTY) Ltd t/a The Geek Network.
 *
 * AIDL surface for the Circle Mesh Service.
 *
 * Wraps the CircleAether protocol (open source at aether-protocol/, the
 * git submodule at repo root) and exposes it to Android apps as a system
 * binder.
 *
 * Transports CircleMesh manages:
 *   - WiFi Direct  (peer-to-peer ~250 m, ~25 Mbps, normal phone hardware)
 *   - BLE GATT     (peer-to-peer ~30 m, ~1 kbps, very low power)
 *   - LoRa         (peer-to-peer ~1-10 km, ~1 kbps, where the device
 *                   has a LoRa modem — rare but real, ZA / IN markets)
 *
 * Routing: each node holds an Ed25519 identity. Messages carry sender
 * fingerprint, target fingerprint (or broadcast topic), TTL, hop count,
 * and a signature over the payload. The service handles forwarding;
 * apps only see send / receive.
 *
 * Callers must hold za.co.circleos.permission.USE_MESH for send and
 * receive operations. Listing peers requires QUERY_MESH (a softer
 * permission usable for status UI without granting send access).
 */

package za.co.circleos.mesh;

import za.co.circleos.mesh.MeshNode;
import za.co.circleos.mesh.MeshHealth;
import za.co.circleos.mesh.IMeshInboxListener;

/** Binder published under SERVICE_NAME = "circle_mesh". */
interface ICircleMeshManager {

    // ----- identity ----------------------------------------------------

    /**
     * The local node's Ed25519 fingerprint, hex-encoded (64 chars).
     * Stable across boots; rotated only via explicit user reset.
     */
    String getLocalNodeId();

    // ----- peers -------------------------------------------------------

    /**
     * Peers currently reachable on any transport. Order: most-recently-
     * seen first. Empty array means no peers found.
     *
     * Requires QUERY_MESH.
     */
    MeshNode[] listKnownPeers();

    /**
     * Health snapshot — number of peers, message-pass rate, transport
     * activity. Cheap; safe to poll for status UI.
     *
     * Requires QUERY_MESH.
     */
    MeshHealth getHealth();

    // ----- messaging ---------------------------------------------------

    /**
     * Send a message to a specific peer. Best-effort, no delivery
     * acknowledgement guaranteed at this layer — apps that need
     * end-to-end confirmation must layer their own ack on the payload.
     *
     * @param targetNodeId  Ed25519 fingerprint of the recipient
     * @param topic         short topic string (1..32 chars, ASCII);
     *                      receivers subscribe per-topic
     * @param payload       opaque bytes, up to 16 KiB; payload-layer
     *                      encryption is the caller's responsibility
     * @param ttl           hop count; clamped to [1..16]
     * @return message id (random 128-bit, hex-encoded), useful for
     *         de-duplication on the receiver
     */
    String sendMessage(in String targetNodeId,
                       in String topic,
                       in byte[] payload,
                       int ttl);

    /**
     * Broadcast a message to every reachable peer that subscribes to
     * {@code topic}. Same payload constraints as {@link #sendMessage}.
     */
    String broadcast(in String topic, in byte[] payload, int ttl);

    /**
     * Subscribe to incoming messages on a topic. The listener fires
     * for every received-and-deduplicated message. Returns a handle for
     * later unsubscription.
     */
    long subscribeInbox(in String topic, in IMeshInboxListener listener);

    void unsubscribeInbox(long handle);

    // ----- versioning --------------------------------------------------

    /** API schema version. */
    int getApiVersion();
}
