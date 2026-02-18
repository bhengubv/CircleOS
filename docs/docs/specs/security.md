# Security Specification

---

## Threat model

Circle OS protects against:

| Threat | Mitigation |
|--------|-----------|
| App tracking / surveillance | Default-deny internet, identifier spoofing, permission auto-revoke |
| Malicious files | File DMZ (CDR pipeline) |
| Zero-click exploits | Behavioral sandbox, DMZ quarantine |
| Network-based attacks | Traffic Lobby, DataAcuity threat feed |
| Physical access | TEE-backed keystore, screen lock, Titanium duress |
| Stalkerware | Notification privacy, clipboard protection, camera/mic indicators |

Circle OS does **not** protect against: hardware implants, baseband attacks, or a fully compromised kernel.

---

## Privacy Engine

### Network permission enforcer

Default policy: no app UID may reach the internet.

Implementation: `INetd.firewallSetUidRule(FIREWALL_CHAIN_DOZABLE, uid, FIREWALL_RULE_DENY)` applied to all new app UIDs at install time via `ACTION_PACKAGE_ADDED` broadcast.

Grants persist to SQLite: `/data/circle/privacy/network_grants.db`

Re-applied after reboot via `reapplyAllGrants()` → `connectToNetd()` with incremental backoff (5s × n, max 60s).

### Identifier spoofing

`FakeResponseProvider` returns consistent but fake values per UID:

| Identifier | Fake value |
|------------|-----------|
| Advertising ID | All-zeros UUID |
| Android ID | Per-UID deterministic hash |
| IMEI | 000000000000000 |
| Serial | CIRCLE000000 |

### Permission auto-revoke

`AutoRevokeJobService` runs every 7 days (JobScheduler, device idle). Revokes permissions unused for 7+ days across all non-system packages.

---

## Security Engine

### Behavioral Sandbox

`BehavioralSandbox` monitors running processes via:

- `/proc/[pid]/syscall` — system call monitoring
- `/proc/net/tcp` and `/proc/net/tcp6` — active connections
- `/proc/[pid]/maps` — memory mappings
- `/proc/[pid]/status` — process state

IPv6 addresses decoded from `/proc/net/tcp6` little-endian format: 32 hex chars = 4 × 32-bit LE words.

Suspicious patterns escalate to `DataAcuityClient` for correlation.

### DataAcuity threat feed

WebSocket connection to DataAcuity threat intelligence. On threat detection:
1. Process is flagged
2. Network access revoked immediately
3. File DMZ activated for all process output
4. Alert logged to privacy log

Public key verified from `ro.circleos.dataacuity.pubkey` SystemProperty (or compiled-in default).

### File DMZ — CDR Pipeline

All inbound files enter quarantine:

```
inbound file
    │
    ▼
[Quarantine] ← JSONL manifest entry
    │
    ▼
[Scanner] ← hash check vs IOC database (ResearcherApiService)
    │
    ▼
[CDR] ← Content Disarm & Reconstruction
    │     Images: MozJPEG re-encode
    │     Documents: structure-level rebuild
    │     Archives: recursive unpack + repack
    │
    ▼
[Release] → user-accessible Downloads/
```

Files that fail CDR go to Malware Jail — accessible only to security researchers via the ResearcherApiService.

---

## OTA signing

Release packages signed with RSA-4096 (PKCS#1 v1.5, SHA-256). Public key in `vendor/circle/signing/keys/releasekey.x509.pem`. Verification in `CircleUpdateService` before any installation begins.
