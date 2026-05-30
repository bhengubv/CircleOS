/*
 * Copyright (C) 2026 The Other Bhengu (PTY) Ltd t/a The Geek Network.
 *
 * AIDL surface for the Circle Security Service.
 *
 * Houses the four-headed security stack from the spec:
 *
 *   1. Traffic Lobby — a local VPN that inspects outbound DNS + TCP
 *      flows. Detects DGA (domain-generation algorithm) entropy
 *      patterns, blocks known-bad domains from the IOC feed, and lets
 *      the user see in plain English which apps phoned where.
 *
 *   2. File DMZ — a quarantine area on the userdata partition. All
 *      downloads land here first; the CDR pipeline scans them; only
 *      then do they appear in the Downloads folder visible to apps.
 *
 *   3. CDR (Content Disarm and Reconstruct) — strips active content
 *      (macros, embedded JS, exploit-likely structures) from PDFs,
 *      Office docs, ZIPs, and images. The reconstructed file is what
 *      the user sees.
 *
 *   4. Zombie Map — community threat intelligence. The phone correlates
 *      observed indicators (suspicious domain, malware hash, phishing
 *      URL) against the Data Acuity threat feed and shows the user a
 *      map of related infrastructure ("this domain is part of a
 *      campaign that also runs from these 14 other IPs").
 *
 * Callers must hold za.co.circleos.permission.QUERY_SECURITY for
 * read operations; mutating operations (quarantine release, manual
 * IOC submission) require MANAGE_SECURITY (signature|privileged).
 */

package za.co.circleos.security;

import za.co.circleos.security.TrafficEvent;
import za.co.circleos.security.QuarantinedFile;
import za.co.circleos.security.ThreatIndicator;

/** Binder published under SERVICE_NAME = "circle_security". */
interface ICircleSecurityManager {

    // ----- Traffic Lobby ---------------------------------------------

    /** Last N outbound flows observed (most recent first). */
    TrafficEvent[] getRecentTrafficEvents(int limit);

    /** Whether the Traffic Lobby VPN is currently up. */
    boolean isTrafficLobbyActive();

    /** Enable / disable the Traffic Lobby. MANAGE_SECURITY required. */
    void setTrafficLobbyEnabled(boolean enabled);

    // ----- File DMZ ---------------------------------------------------

    /** Files currently held in quarantine pending CDR. */
    QuarantinedFile[] listQuarantine();

    /**
     * Release a quarantined file into the user's downloads folder,
     * skipping CDR. Should only be used after the user explicitly
     * acknowledges the risk in CircleSettings.
     */
    void releaseFromQuarantine(in String quarantineId, in String reason);

    /** Delete a quarantined file outright. */
    void deleteFromQuarantine(in String quarantineId);

    // ----- Threat indicators -----------------------------------------

    /** Lookup an IOC against the loaded Data Acuity feed. */
    ThreatIndicator lookupIndicator(in String indicator);

    /**
     * Submit a manually-observed indicator (e.g. a suspicious SMS URL)
     * to the local store; if upload is allowed, it is forwarded to the
     * Data Acuity feed for community correlation.
     */
    void reportIndicator(in String indicator, in String observation);

    /**
     * Get the Zombie Map for a campaign id. Returns the set of related
     * indicators correlated by Data Acuity (other domains, IPs, hashes
     * from the same campaign).
     */
    ThreatIndicator[] getZombieMap(in String campaignId);

    // ----- versioning -------------------------------------------------

    int getApiVersion();
}
