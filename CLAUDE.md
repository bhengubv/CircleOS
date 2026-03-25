Autonomous: On

# Circle OS & Data Acuity — Claude Code Instructions

> **"Slow is smooth. Smooth is fast. Fast leads to delivery."**

This document provides everything Claude Code needs to autonomously develop Circle OS components and the Data Acuity threat intelligence platform.

---

## PROJECT OVERVIEW

```
CIRCLE OS:         Privacy-first mobile OS (Android-based)
DATA ACUITY:       Threat intelligence platform (backend)
THE GEEK NETWORK:  Parent ecosystem (SDPKT, SleptOn, Bruh!)
```

**Repository Paths (relative to project root):**
```
SPEC ROOT:         ./                     # This specification
SPEC CHAPTERS:     ./chapters/            # Detailed chapters
CIRCLE OS CODE:    ../src/circleos/       # AOSP fork (convention)
DATA ACUITY CODE:  ../src/dataacuity/     # .NET backend (convention)
```

> **Note:** Paths are relative. On your machine, the project root might be
> `C:\Dev\Operating System\CircleOS\` (Windows) or `~/circleos/` (Linux).
> Adapt paths to your environment.

---

## CORE PHILOSOPHY

```
PRIVACY:      User data belongs to users. No tracking. No selling. Ever.
SECURITY:     Defense in depth. Assume breach. Contain and expose.
TRANSPARENCY: Document limitations. No security theater.
COMMUNITY:    Every attack makes everyone smarter.
SOVEREIGNTY:  African-owned, African-controlled, African-serving.
```

---

## BRAND IDENTITY

```
TAGLINE:      "You're NOT the product. Trust!"
MEANING:      Circle of Trust — you're inside, we protect our own
VOICE:        Confident, warm, honest, inclusive
AESTHETIC:    Organised warmth — premium without pretension
```

KEY COLORS:
```
Circle Deep:    #1A1F36    (primary dark)
Circle Warm:    #F5F0EB    (primary light)
Circle Gold:    #D4A574    (accent)
Sage:           #7D9B8A    (success/protected)
Terracotta:     #C17B5D    (warning/attention)
Blocked Red:    #C45C5C    (threats blocked)
```

BRAND PHRASES:
```
Onboarding:     "Welcome to the Circle."
Protected:      "The Circle protected you."
Community:      "47,832 people in your Circle."
```

---

## TECHNOLOGY STACK

### Circle OS (Mobile)

```
PLATFORM:     Android 14 (AOSP fork)
LANGUAGES:    Kotlin (preferred), Java, C/C++ (native)
BUILD:        Gradle, AOSP build system
UI:           Jetpack Compose
ARCHITECTURE: MVVM, Clean Architecture
CRYPTO:       Tink (Google), libsodium
MESH:         WiFi Direct, Bluetooth LE
DATABASE:     SQLite (SQLCipher for encrypted)
```

### Data Acuity (Backend)

```
PLATFORM:     Python 3.11+ / FastAPI
LANGUAGES:    Python
DATABASE:     PostgreSQL 16
CACHE:        Redis 7
SEARCH:       Elasticsearch 8
QUEUE:        RabbitMQ / Redis Streams
STORAGE:      S3-compatible (Minio)
CONTAINER:    Docker
HOSTING:      The Geek Network infrastructure
```

---

## CHAPTER REFERENCE

| Ch | File | Topic | Implementation |
|----|------|-------|----------------|
| 01-17 | [existing] | Core OS | AOSP fork |
| 18 | 18_mesh_networking.txt | Mesh protocol | CircleMeshService |
| 19 | 19_firewall_lobby.txt | Firewall + Traffic Lobby | CircleFirewallService |
| 20 | 20_malware_jail.txt | Malware containment | MalwareJailService |
| 21 | 21_threat_telemetry.txt | Community defense | ThreatIntelService |
| 22 | 22_data_acuity_platform.txt | Backend platform | DataAcuity.Api |
| 23 | 23_brand_design_system.txt | Brand & UI Design | Design tokens, components |

**Read the chapter BEFORE implementing. Each contains detailed specs.**

---

## DIRECTORY STRUCTURE

### Circle OS (AOSP)

```
frameworks/base/services/core/java/com/circleos/server/
├── mesh/
│   ├── CircleMeshService.java          # Main mesh daemon
│   ├── MeshDaemon.java                 # Background worker
│   ├── transport/
│   │   ├── ITransport.java             # Transport interface
│   │   ├── WifiDirectTransport.java    # WiFi Direct impl
│   │   └── BluetoothTransport.java     # BLE impl
│   ├── routing/
│   │   ├── RoutingTable.java           # Peer routing
│   │   └── GossipRouter.java           # Gossip protocol
│   ├── crypto/
│   │   ├── MeshCrypto.java             # X25519, XChaCha20
│   │   └── KeyManager.java             # Key storage
│   └── storage/
│       ├── MessageStore.java           # Store-and-forward
│       └── PeerStore.java              # Known peers
│
├── firewall/
│   ├── CircleFirewallService.java      # Main firewall
│   ├── PolicyEngine.java               # Per-app policies
│   ├── TrafficLobby.java               # Quarantine system
│   ├── ThreatScanner.java              # YARA + threat intel
│   ├── VpnInterceptor.java             # VPN-based capture
│   ├── DnsInterceptor.java             # DNS filtering
│   └── db/
│       ├── PolicyDatabase.java
│       ├── ThreatIntelDatabase.java
│       └── ConnectionLogDatabase.java
│
├── malwarejail/
│   ├── MalwareJailService.java         # Main jail service
│   ├── JailController.java             # Manage jailed apps
│   ├── HoneypotManager.java            # Fake data generation
│   ├── SyscallInterceptor.java         # seccomp + ptrace
│   ├── C2Sinkhole.java                 # Fake C2 server
│   ├── IntelCollector.java             # Intelligence gathering
│   └── ReportGenerator.java            # User reports
│
└── threatintel/
    ├── ThreatIntelService.java         # Main service
    ├── ThreatDatabase.java             # Local threat DB
    ├── ThreatFeedSync.java             # Feed updates
    ├── ThreatReporter.java             # Submit reports
    ├── CanaryManager.java              # Canary tokens
    └── FirewallIntegration.java        # Connect to firewall

packages/apps/
├── CircleMessages/                     # Mesh messaging app
├── CircleBeacon/                       # Emergency beacon
└── CircleSettings/
    └── src/com/circleos/settings/
        ├── firewall/
        ├── malwarejail/
        └── communitydefense/
```

### Data Acuity (Backend) — Separate Repo

> **Note:** Data Acuity lives in `/Users/admin/Code/Dev/dataacuity/`, NOT in this repo.
> See `dataacuity/CLAUDE.md` for full details.

```
dataacuity/
├── suite/                    # Master orchestration (Traefik, Keycloak)
├── markets/                  # Financial markets data (OpenBB)
├── maps/                     # Geospatial platform (PostGIS, OSRM)
├── api-gateway/              # Unified API gateway
├── monitoring/               # Prometheus, Grafana, Loki
├── data-warehouse/           # Analytics PostgreSQL
├── dbt/                      # Data transformation
├── superset/                 # BI dashboards
├── n8n/                      # Workflow automation
├── twenty/                   # CRM
├── morph/                    # File converter
├── ai-brain/                 # Ollama + Open WebUI
└── portal/                   # Landing page
```

---

## KEY APIS

### Circle OS Binder Interfaces

```java
// ICircleMeshService.aidl
interface ICircleMeshService {
    void sendMessage(in byte[] recipientPubKey, in byte[] payload, in MeshMessageOptions options);
    void registerReceiver(String appId, IMessageReceiver callback);
    List<MeshPeer> getNearbyPeers();
    MeshStatus getStatus();
}

// ICircleFirewallService.aidl
interface ICircleFirewallService {
    AppNetworkPolicy getPolicy(String packageName);
    void setPolicy(String packageName, in AppNetworkPolicy policy);
    List<LobbyEntry> getPendingLobbyEntries();
    void resolveLobbyEntry(String entryId, boolean allow);
    List<ConnectionLog> getConnectionLog(long since, int limit);
}

// IMalwareJailService.aidl
interface IMalwareJailService {
    List<JailedApp> getJailedApps();
    JailStatus getJailStatus(String packageName);
    MalwareIntelligence getIntelligence(String packageName);
    byte[] generateReport(String packageName, String format);
    void shareAnonymously(String packageName);
}

// IThreatIntelService.aidl
interface IThreatIntelService {
    ThreatMatch checkDomain(String domain);
    ThreatMatch checkIP(String ip);
    void reportThreat(in ThreatReport report);
    CanaryToken createCanary(CanaryType type);
}
```

### Data Acuity REST API

```
BASE: https://api.dataacuity.co.za/v1

# Public endpoints (no auth)
POST /threat/submit           # Circle OS submits threat report
GET  /threat/feed             # Circle OS fetches threat feed
POST /canary/register         # Register canary token
GET  /stats/public            # Public statistics

# Authenticated endpoints (API key)
GET  /ioc/lookup?type=&value= # Lookup single IOC
POST /ioc/bulk-lookup         # Bulk IOC lookup
GET  /campaign/{id}           # Campaign details
GET  /feed/full               # Full feed (enterprise)
```

---

## DATABASE SCHEMAS

### Circle OS (SQLite)

```sql
-- /data/circle/threat_intel/threat.db
CREATE TABLE threat_domains (
    domain TEXT PRIMARY KEY,
    threat_type TEXT NOT NULL,
    severity TEXT NOT NULL,
    campaign_id TEXT,
    first_seen INTEGER,
    last_updated INTEGER,
    source TEXT
);

CREATE TABLE threat_ips (
    ip TEXT NOT NULL,
    cidr INTEGER DEFAULT 32,
    threat_type TEXT NOT NULL,
    severity TEXT NOT NULL,
    PRIMARY KEY (ip, cidr)
);

-- /data/circle/firewall/connections.db
CREATE TABLE connections (
    id INTEGER PRIMARY KEY,
    timestamp INTEGER NOT NULL,
    app_package TEXT NOT NULL,
    dest_domain TEXT,
    dest_ip TEXT,
    dest_port INTEGER,
    decision TEXT,
    threat_match TEXT
);

-- /data/circle/honeypot/
-- Fake contacts, messages, photos, etc.
```

### Data Acuity (PostgreSQL)

```sql
-- See Chapter 22 for full schema
-- Key tables:
CREATE TABLE iocs (
    id UUID PRIMARY KEY,
    type VARCHAR(20) NOT NULL,           -- ip, domain, hash
    value TEXT NOT NULL,
    threat_type VARCHAR(50),             -- c2, malware, phishing
    severity VARCHAR(20) NOT NULL,       -- low, medium, high, critical
    confidence INTEGER DEFAULT 50,
    first_seen TIMESTAMP WITH TIME ZONE,
    last_seen TIMESTAMP WITH TIME ZONE,
    reports_count INTEGER DEFAULT 1,
    campaign_id UUID REFERENCES campaigns(id),
    source VARCHAR(50)
);

CREATE TABLE campaigns (
    id UUID PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    actor_type VARCHAR(50),              -- state, criminal, unknown
    targets TEXT[],
    target_regions VARCHAR(2)[],
    first_seen TIMESTAMP WITH TIME ZONE,
    last_active TIMESTAMP WITH TIME ZONE
);

CREATE TABLE threat_reports (
    id UUID PRIMARY KEY,
    received_at TIMESTAMP WITH TIME ZONE,
    country_code VARCHAR(2),
    threat_type VARCHAR(50),
    severity VARCHAR(20),
    report_data JSONB NOT NULL,
    processed BOOLEAN DEFAULT FALSE
);

CREATE TABLE canary_tokens (
    id UUID PRIMARY KEY,
    type VARCHAR(20) NOT NULL,           -- email, phone, document, dns
    value TEXT NOT NULL UNIQUE,
    device_hash VARCHAR(64) NOT NULL,
    triggered BOOLEAN DEFAULT FALSE
);

CREATE TABLE canary_triggers (
    id UUID PRIMARY KEY,
    canary_id UUID REFERENCES canary_tokens(id),
    triggered_at TIMESTAMP WITH TIME ZONE,
    source_ip INET,
    user_agent TEXT
);
```

---

## CRYPTOGRAPHIC STANDARDS

```
KEY EXCHANGE:       X25519 ECDH
SYMMETRIC:          XChaCha20-Poly1305
SIGNATURES:         Ed25519
KEY DERIVATION:     HKDF-SHA256
HASHING:            SHA-256, BLAKE2b
TLS:                1.3 only, certificate pinning
DATABASE:           SQLCipher (256-bit AES)
```

---

## STATUS AUDIT (2026-03-25)

### What's Complete (all confirmed via session state)
```
✅ OS Core Privacy Framework (Phases 1-5)
✅ Inference Service (Phases 1-4) — llama.cpp + BitNet, Rust JNI, InferenceBridge
✅ Personality Engine (Phases 1-5) — 20+ modes, auto-switch, custom modes
✅ Design System — 50 files, mode overlays, Comfortaa font, a11y audit
✅ Security Architecture (Phases 1-3) — File DMZ, CDR, Traffic Lobby, threat feeds, malware jail, STIX 2.1
✅ Compression (Phases 1-2) — image/doc/archive/video/audio, ZSTD, metadata stripping
✅ Mesh Networking (core) — BLE GATT + WiFi Direct, gossip routing, crypto
✅ OTA Updates (Phases 1-9) — mesh P2P delivery, A/B delta, remote commands, enrollment
✅ SDPKT Titanium (Phases 1-6) — TEE wallet, NFC P2P, offline TX, multi-device
✅ Apps: CircleMessages, Butler, CircleSettings, InferenceBridge, PersonalityTile/Editor, SdpktTitanium, TrafficLobby
✅ .NET cross-platform: CircleInference client, CircleDesign tokens, 3 Geek Network app integrations
✅ Docs: MkDocs site, feature pages, press kit, installation guides
```

### What's NOT Done
```
❌ Build not confirmed — last status was "Soong analysis phase" (Feb 20). No working emulator image verified.
❌ No automated tests — zero CTS/unit tests for any Circle OS service
❌ ZSTD JNI native library — ZstdCompressor.java loads libcircle_zstd_jni.so but Android.bp entry not created
❌ Store-and-forward for mesh — architecture in place, message queue deferred
❌ CircleBeacon emergency app — not started
❌ SDPKT settlement backend validation — HTTP POST to staging not tested e2e
❌ No CI/CD — 3 GitHub workflows exist but AOSP needs a Linux build server (not GitHub Actions)
❌ Data Acuity backend mismatch — CLAUDE.md describes .NET backend, actual implementation is Python/Docker in dataacuity repo
❌ a.out committed to aosp/ — stale binary, should be gitignored
❌ /Volumes/AndroidOut/out symlink — build output on external volume, not portable
```

### IMPLEMENTATION PRIORITIES (Updated 2026-03-25)

**Original phases are DONE.** Remaining work:

### Low-Hanging Fruit (can do now, minimal effort)

```
1. Clean up a.out from aosp/ — add to .gitignore, git rm
   Effort: 2 minutes

2. Add ZSTD Android.bp entry — cc_library_shared for libcircle_zstd_jni.so
   Effort: 30 minutes (Android.bp boilerplate + link external/zstd)

3. Fix Data Acuity architecture docs — update this file to reflect that
   Data Acuity backend is Python/FastAPI/Docker (in dataacuity repo),
   NOT .NET/C# as described in the directory structure and code standards sections
   Effort: 15 minutes

4. Update session state — mark build status, remove stale "Running" state
   Effort: 10 minutes

5. Settlement backend test — send test HTTP POST from emulator/device
   to sleptonapi.thegeeknetwork.co.za/api/sdpkt/settle and verify 200/409
   Effort: 15 minutes (once build works)
```

### Next Priorities (require more effort)

```
6. Verify build — CANNOT build on MacInCloud (57GB free, need 250GB+).
   AOSP source is 138GB, out/ symlink to /Volumes/AndroidOut/ (not mounted).
   Need a dedicated build server or the original dev machine with the
   AndroidOut volume attached.
   Blocker: Disk space + build volume

7. Add unit tests for security services — CDR processor, threat scanner,
   quarantine manager, behavioral sandbox. These are pure Java, testable
   without a running device.
   Effort: 1-2 days

8. Complete store-and-forward for mesh — queue messages when peers are
   offline, deliver when they reconnect. Architecture exists in MessageStore.
   Effort: 1-2 days

9. Build CircleBeacon app — emergency beacon using mesh network for
   offline SOS. Should integrate with PanikAPI when internet available.
   Effort: 2-3 days

10. Set up build server — .106 is too small (2 CPU, 23GB RAM).
    AOSP needs 16+ cores, 64GB RAM, 500GB SSD minimum.
    Options: dedicated hardware, cloud instance (Hetzner AX102 ~€130/mo),
    or GitHub-hosted large runners.
    Effort: 1 day setup + ongoing cost
```

### Future Phases
```
11. Device porting — GSI (Generic System Image) for Treble devices,
    Huawei P30 Lite (reference hard-mode device)
12. Circle Store integration with SleptOnAPI — app distribution
13. Data Acuity threat feed production pipeline — connect to dataacuity
    repo services (Superset dashboards, threat correlation)
14. Hardware partnership — RISC-V native device with NearLink
```

---

## CIRCLEOS NEXT — STRATEGIC DIRECTION (2026-03-25)

### Decision: OpenHarmony as new base OS

CircleOS is evolving from an AOSP (Android 14) fork to an **OpenHarmony-based** OS. The AOSP version in this repo becomes the reference/archive. A new `circleos-next` repo will hold the OpenHarmony-based implementation.

### Why OpenHarmony
- Runs on devices from 128KB RAM (IoT) to flagship phones — AOSP needs 2GB+
- Built-in distributed networking (DSoftBus) — natural fit for Aether mesh
- RISC-V production ready — aligns with custom hardware vision
- Zero Google dependency — no GMS baggage
- Component-based — strip to minimum for $30-50 phones
- ArkTS (TypeScript-based) — Aether protocol already has TypeScript implementation

### What carries over from this repo
- **100% portable:** Privacy framework concepts, mesh protocol (Aether), threat intelligence, offline-first design, AI inference (llama.cpp), app store policies, age modes, personality engine, brand design system
- **Aether protocol is the key asset** — open source at `/Users/admin/Code/Dev/aether-protocol/`, 8 language implementations (C for OS daemon, TypeScript for ArkTS native apps, Rust for security, .NET for Geek Network apps). Transport-agnostic — just needs OpenHarmony BLE/NearLink transports.
- **Not portable:** AOSP framework patches, SELinux policies, Soong build system, ART modifications, device trees

### Device roadmap
1. **Phase 1 (months 3-6):** Mid-range phone (Xiaomi/Samsung A-series) — CircleOS Next with privacy + mesh + Geek Network Blazor apps in WebView
2. **Phase 2 (months 7-10):** Ultra-low-cost $30-50 phone (MediaTek MT6739/MT6761) — stripped OpenHarmony, essential apps only, mesh critical
3. **Phase 3 (months 11-18):** Custom RISC-V hardware with NearLink + secure element
4. **Phase 4 (months 18+):** Multi-device — watch, TV, IoT gateway, vehicle

### App strategy
- **Now:** Geek Network apps (SDPKT, Bruh, TxTMe, KiffStore, SleptOn) ship as Blazor WebView — no rewrite
- **Later:** Rewrite to native ArkTS as OS matures
- **Android compat:** Compatibility layer for WhatsApp, banking, M-Pesa (via Eclipse Oniro / Jolla AppSupport)

### Africa-first principles
1. Offline by default — mesh fills the gap
2. Data-frugal — compress everything, never auto-download
3. Multi-SIM native — dual/triple SIM, USSD integration
4. Load shedding aware — battery management during outages
5. Low-literacy friendly — voice-first UI, icon-heavy
6. Local languages — Zulu, Xhosa, Sotho, Swahili, Yoruba, Amharic day one
7. Financial inclusion — SDPKT wallet offline via NFC
8. No surveillance tax — no data collection, no ads, ever

### Build blocker
Cannot build on MacInCloud (72GB free, need 100GB+). Need dedicated build server: Hetzner AX102 (~€130/mo, 12-core Ryzen, 64GB RAM, 2x1TB NVMe) or equivalent.

### Full plan
`/Users/admin/.claude/plans/parsed-growing-clover.md`

---

## CODE STANDARDS

### Kotlin (Circle OS)

```kotlin
// Use coroutines for async
suspend fun fetchThreatFeed(): ThreatFeed {
    return withContext(Dispatchers.IO) {
        api.getFeed()
    }
}

// Use sealed classes for states
sealed class JailStatus {
    object Active : JailStatus()
    data class Contained(val since: Long) : JailStatus()
    object Removed : JailStatus()
}

// Extension functions for clarity
fun String.toSha256(): String = 
    MessageDigest.getInstance("SHA-256")
        .digest(this.toByteArray())
        .toHexString()
```

### Python (Data Acuity)

```python
# Use FastAPI with Pydantic models
from pydantic import BaseModel

class ThreatReportDto(BaseModel):
    schema_version: str
    report_type: str
    country: str
    timestamp: datetime
    indicators: IndicatorsDto

# Use async endpoints
@app.post("/threat/submit")
async def submit_report(report: ThreatReportDto):
    await validate(report)
    report_id = await db.insert(report)
    await queue.enqueue(AnalysisJob(report_id))
    return {"status": "accepted", "report_id": report_id}

# Use dependency injection
async def get_db() -> AsyncGenerator[Database, None]:
    async with database_pool.acquire() as conn:
        yield conn
```

---

## TESTING REQUIREMENTS

### Unit Tests

```
COVERAGE TARGET: 80%+

Circle OS:
- All crypto functions
- Routing table operations
- Policy evaluation
- Threat matching
- Anonymization

Data Acuity:
- IOC normalization
- Report validation
- Feed generation
- Canary matching
```

### Integration Tests

```
Circle OS:
- Firewall blocks known-bad domain
- Lobby holds suspicious connection
- Jail contains malware
- Mesh delivers message (3-hop)

Data Acuity:
- Submit report → creates IOC
- IOC lookup returns match
- Canary trigger notifies device
- Feed contains recent threats
```

---

## SECURITY CHECKLIST

Before any PR:

```
□ No hardcoded secrets
□ All user data encrypted at rest
□ TLS for all network calls
□ Input validation on all endpoints
□ Rate limiting implemented
□ No PII in logs
□ Audit logging for sensitive operations
□ Memory cleared after crypto operations
```

---

## QUICK DECISIONS

```
"Should I log user data?"       → No. Log events, not content.
"Should I store this forever?"  → No. Set retention policy.
"Should I trust this input?"    → No. Validate everything.
"Should I skip encryption?"     → No. Always encrypt.
"Should I call home?"           → Only if user opted in.
"Should I block or lobby?"      → When in doubt, lobby.
```

---

## ERROR HANDLING

```kotlin
// Circle OS: Use Result type
fun checkThreat(domain: String): Result<ThreatMatch> {
    return runCatching {
        threatDb.lookup(domain) ?: ThreatMatch.None
    }
}
```

```csharp
// Data Acuity: Use problem details
[HttpPost("submit")]
public async Task<IActionResult> Submit([FromBody] ThreatReportDto report)
{
    try {
        var result = await _service.Process(report);
        return Ok(result);
    } catch (ValidationException ex) {
        return BadRequest(new ProblemDetails {
            Title = "Validation Failed",
            Detail = ex.Message
        });
    }
}
```

---

## ENVIRONMENT VARIABLES

### Circle OS (Build)

```bash
CIRCLE_BUILD_TYPE=userdebug
CIRCLE_THREAT_FEED_URL=https://api.dataacuity.co.za/v1/threat/feed
CIRCLE_CANARY_DOMAIN=canary.circelos.org
```

### Data Acuity (Runtime)

```bash
ASPNETCORE_ENVIRONMENT=Production
ConnectionStrings__Default=Host=db;Database=dataacuity;Username=app;Password=${DB_PASSWORD}
Redis__Connection=redis:6379
SDPKT_API_URL=https://api.sdpkt.co.za
SDPKT_API_KEY=<secret>
```

---

## DEPLOYMENT

### Data Acuity

```bash
# Build
docker build -t dataacuity:latest .

# Deploy (The Geek Network infrastructure)
docker-compose up -d

# Migrations
dotnet ef database update
```

### Circle OS

```bash
# Setup AOSP
repo init -u https://github.com/circleos/manifest.git
repo sync -j8

# Build
source build/envsetup.sh
lunch circle_arm64-userdebug
make -j$(nproc)
```

---

## INTEGRATION POINTS

### SDPKT (Side Pocket Wallet)

```csharp
// Pay relay rewards
POST https://api.sdpkt.co.za/api/wallet/credit
{
    "wallet_id": "...",
    "amount": 10.00,
    "currency": "ZAR",
    "reason": "Circle mesh relay reward",
    "source": "dataacuity"
}
```

### SleptOn (App Store)

```
// Distribute Circle OS updates
// Distribute threat feed updates
// Manage relay reward pool
```

---

## MONITORING

```yaml
# Prometheus metrics
dataacuity_reports_received_total
dataacuity_iocs_created_total
dataacuity_active_campaigns
dataacuity_canary_triggers_total
dataacuity_api_latency_seconds
```

---

## LEGAL

```
LICENSE:    GPL v3 (Circle OS), AGPL v3 (Data Acuity)
COPYRIGHT:  Circle Foundation (OS), The Geek (Pty) Ltd (Data Acuity)
```

---

## MANTRA

```
Slow is smooth.
Smooth is fast.
Fast leads to delivery.
Delivery leads to satisfaction.
Satisfaction leads to peace of mind.

For all concerned.
```

---

*Circle OS Specification v2.0 — January 2026*
