# Butler Voice Mode — "Her" for CircleOS

## Context

Butler is CircleOS's on-device AI assistant. Today it's a text box. The vision is a voice-first companion that works across phone, watch, and all devices — like Samantha from "Her" but privacy-first and Africa-aware. Voice is essential for watches (no keyboard) and for low-literacy users (voice-first UI, icon-heavy).

---

## Architecture: Voice Across Form Factors

```
┌─────────────────────────────────────┐
│           WATCH (512MB)             │
│  Wake word (DSP) → STT (offload)   │
│  → Phone inference → TTS (local)   │
│  NFC payments, health sensors      │
└──────────────┬──────────────────────┘
               │ BLE/Aether
┌──────────────▼──────────────────────┐
│           PHONE (2-8GB)             │
│  Wake word (local) → STT (local)   │
│  → LLM inference (local) → TTS    │
│  Full Butler: chat, skills, mesh   │
└──────────────┬──────────────────────┘
               │ Aether mesh
┌──────────────▼──────────────────────┐
│     IoT GATEWAY / TV / CAR         │
│  Always-listening (mains power)    │
│  STT + LLM + TTS (all local)      │
│  Home control, Panik SOS relay     │
└─────────────────────────────────────┘
```

---

## Voice Stack (All On-Device, Privacy-First)

### STT (Speech-to-Text)

| Device | Engine | Model Size | RAM | Latency | Offline |
|---|---|---|---|---|---|
| **Phone (2GB+)** | Sherpa-ONNX | ~50MB | ~300MB | <1s | Yes |
| **Phone (4GB+)** | Whisper.cpp tiny | ~75MB | ~400MB | <2s | Yes |
| **Watch (512MB)** | Offload to phone via BLE | 0 | 0 | +200ms BLE | Yes (via phone) |
| **IoT/TV** | Whisper.cpp small | ~240MB | ~600MB | <1s | Yes |

**Why Sherpa-ONNX for phones:** Supports HarmonyOS natively, RISC-V, ONNX runtime (no PyTorch dependency), streaming recognition, 12 programming language bindings. Perfect for OpenHarmony.

**African language support:** Train custom models using:
- WAXAL dataset (21 Sub-Saharan languages, 11k+ hours)
- NCHLT corpus (SA's 11 official languages)
- BibleTTS (10 African languages, 86 hours studio quality)
- Target day-one: English, isiZulu, Swahili. Add Xhosa, Sotho, Yoruba in v2.

### TTS (Text-to-Speech)

| Device | Engine | Model Size | Quality | Latency |
|---|---|---|---|---|
| **Phone** | Piper TTS | ~60MB | Natural | <200ms |
| **Watch** | Kitten TTS | ~25MB | Good | <100ms |
| **IoT/TV** | Piper TTS | ~60MB | Natural | <200ms |
| **$30 phone** | espeak-ng | ~5MB | Robotic but clear | <50ms |

**Why Piper for phones:** 30+ languages, ONNX-based VITS, Raspberry Pi proven, open source, actively maintained. Can train custom voices on African language datasets.

**Why Kitten for watches:** 15-80M parameters, int8 quantized, CPU-only, runs in browsers — the absolute smallest production TTS. Perfect for 512MB watch.

### Wake Word

| Device | Method | Power | Latency |
|---|---|---|---|
| **Phone** | Sherpa-ONNX keyword spotter | ~50mA | <500ms |
| **Watch** | Hardware DSP (Syntiant/Vesper) | ~10µA | <200ms |
| **IoT** | Always-listening (mains power) | N/A | <200ms |
| **Phone (battery save)** | Button press (no wake word) | 0 | 0 |

**Watch reality:** Always-listening on a watch destroys battery unless you have a dedicated DSP chip (10µA vs 50mA). For v1, use button press. For Circle native hardware (Phase 3), integrate Syntiant NDP101 DSP.

**Wake phrase:** "Hey Circle" or customisable per personality mode.

---

## Butler Voice Modes by Device

### Phone Butler (Full)
```
User: [speaks] "What's my balance?"
Butler: [wake word detected] → STT → "What's my balance?"
       → WalletSkill intercepts → SDPKT query → ₷2,450.00
       → TTS → [speaks] "Your balance is two thousand four hundred and fifty Shongololo"
       Latency: ~2-3 seconds total
```

**Features:**
- Full LLM inference (Qwen 0.5B-1.5B)
- All skills (wallet, mesh, call screening)
- Conversation memory (SQLite, encrypted)
- Personality-aware voice tone
- Proactive suggestions (context-aware)
- Multi-turn conversation (50+ turns)

### Watch Butler (Thin Client)
```
User: [button press] "Pay fifty rand"
Watch: STT offloaded to phone via BLE → "Pay fifty rand"
       → Phone LLM → "Hold your watch near the payment terminal"
       → Kitten TTS on watch → [speaks response]
       → NFC payment ready
       Latency: ~3-4 seconds (including BLE round trip)
```

**Features:**
- Voice input → BLE to phone → response back → TTS locally
- SDPKT NFC payments (tap to pay)
- Health sensor data (HR, GSR → stress detection on phone)
- Quick replies ("yes", "no", "cancel" — local, no phone needed)
- Haptic feedback for confirmations
- Watchface complications (balance, mesh peer count)

### IoT Gateway Butler (Always-On)
```
User: [speaks] "Hey Circle, is anyone home?"
Butler: → STT → LLM → checks mesh peer count + family devices
       → TTS → "Two devices are connected to the mesh.
                 Thabo's phone was last seen 10 minutes ago."
       Latency: ~2 seconds
```

**Features:**
- Always-listening (mains power, no battery concern)
- Mesh relay node (bridges offline devices to internet)
- Panik SOS relay (receives mesh emergency broadcasts, calls emergency services)
- Home context (who's connected, device status)
- Load shedding awareness ("Power will go out in 30 minutes. Syncing your data now.")

---

## Personality-Aware Voice

Butler's voice and behaviour adapt per personality mode:

| Mode | Voice Tone | Behaviour | Example |
|---|---|---|---|
| **Daily** | Warm, friendly | Conversational, helpful | "Hey! Your balance is ₷2,450. You spent ₷120 today." |
| **Work** | Professional, concise | Brief, no small talk | "Balance: ₷2,450. ₷120 spent today." |
| **Secure** | Calm, measured | Privacy-first, minimal disclosure | "Your balance is available in the wallet app." |
| **Elder** | Slow, clear, patient | Repeats if needed, simple words | "You have two thousand four hundred and fifty rand. Would you like to hear it again?" |
| **Kid** | Cheerful, encouraging | Educational, age-appropriate | "You have lots of money saved up! Great job!" |
| **Night** | Whisper-quiet, dim | Minimal speech, low volume | [whispered] "Two four fifty." |
| **Trader** | Analytical, data-rich | Market-aware, JSE context | "Balance ₷2,450. Shongololo is up 3.2% today. Markets close in 2 hours." |

**Implementation:** System prompt prefix per mode + TTS speed/pitch/volume adjustments. The Personality Engine already provides the mode — just needs wiring.

---

## Conversation Memory ("She Remembers")

**What Samantha did:** Remembered everything. Referenced past conversations. Evolved through the relationship.

**Butler implementation:**

```sql
-- On-device only. Never synced. Encrypted with SQLCipher.
CREATE TABLE conversations (
    id TEXT PRIMARY KEY,
    started_at INTEGER NOT NULL,
    personality_mode TEXT,
    summary TEXT  -- LLM-generated summary after conversation ends
);

CREATE TABLE messages (
    id TEXT PRIMARY KEY,
    conversation_id TEXT REFERENCES conversations(id),
    role TEXT NOT NULL,  -- 'user' or 'butler'
    content TEXT NOT NULL,
    timestamp_ms INTEGER NOT NULL,
    voice_duration_ms INTEGER  -- how long the voice clip was
);

CREATE TABLE user_preferences (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    learned_at INTEGER NOT NULL,
    confidence REAL DEFAULT 0.5  -- how sure Butler is about this preference
);
-- Example: ("preferred_language", "isiZulu", 1709123456, 0.9)
-- Example: ("greeting_style", "formal", 1709123456, 0.6)
```

**Memory levels:**
1. **Session memory** — within current conversation (context window, up to 50 turns)
2. **Preference memory** — learned patterns persisted to SQLite (language, tone, topics of interest)
3. **Conversation summaries** — LLM summarises each conversation on close, searchable later
4. **Never stored:** Financial data (WalletSkill handles live), message content from TxTMe, location history

---

## Proactive Butler ("She Initiated")

**What Samantha did:** Started conversations. Noticed things. Offered help without being asked.

**Butler proactive triggers (privacy-respecting):**

| Trigger | Context | Butler Says |
|---|---|---|
| **Load shedding in 30min** | Schedule API + location | "Power goes out at 2pm. I'm syncing your data now." |
| **Morning routine** | Time + personality mode | "Good morning. You have 3 unread messages and your balance is ₷2,450." |
| **Payment received** | SDPKT webhook | "You just received ₷500 from Thabo." |
| **Mesh peer nearby** | Aether discovery | "Sipho's phone is nearby. Want to send a message?" |
| **App error healed** | Wolverine Tier 1 | "KiffStore had a hiccup but it's fixed now." |
| **Job match** | TheJobCenter API | "A new job matching your profile was posted today." |
| **Travel deal** | Takemehome API | "Flights to Cape Town dropped 30% this week." |
| **Idle for 2 hours** | No interaction | [silence — Butler doesn't nag] |

**Key design principle:** Butler asks, never assumes. "Want to hear your messages?" not "Here are your messages." Respect attention.

---

## Implementation Phases

### Phase 1: Voice Foundation (2 weeks)
- Integrate Sherpa-ONNX STT into Butler (phone only)
- Integrate Piper TTS into Butler (phone only)
- Voice toggle in ChatActivity (mic button → STT → text → LLM → TTS → speaker)
- No wake word yet (button-activated)
- English only

### Phase 2: Conversation Memory (1 week)
- SQLCipher conversation database
- Session context (multi-turn within conversation)
- Conversation summaries on close
- "What did we talk about last time?" works

### Phase 3: Personality Voice (1 week)
- Wire personality mode → system prompt
- TTS speed/pitch/volume per mode
- Elder mode: slower, clearer, repeat option
- Night mode: whisper volume
- Secure mode: minimal disclosure

### Phase 4: Watch Thin Client (2 weeks)
- BLE voice offload protocol (watch → phone → response → watch)
- Kitten TTS on watch (25MB)
- Button-press activation on watch
- SDPKT payment confirmation via voice
- Watch personality mode (Compact)

### Phase 5: Proactive Butler (2 weeks)
- Background service with context polling (low frequency, battery-efficient)
- Load shedding integration
- Morning briefing
- Payment notifications via voice
- Mesh peer announcements

### Phase 6: African Languages (3 weeks)
- Train isiZulu STT on NCHLT + WAXAL data
- Train isiZulu TTS on BibleTTS + NCHLT data
- Train Swahili STT/TTS
- Language auto-detection (code-switching support — mix of English + Zulu common in SA)

### Phase 7: Wake Word + Always-On (2 weeks)
- "Hey Circle" wake word via Sherpa-ONNX
- IoT gateway always-listening mode
- Phone: wake word only when charging (battery preservation)
- Watch: deferred until Circle native hardware with DSP

### Phase 8: Emotional Intelligence (3 weeks)
- Sentiment detection from voice prosody (pitch, speed, energy)
- Typing speed analysis (text mode)
- Response tone adaptation
- Compassionate mode for detected stress
- Celebrate mode for detected excitement

---

## "Her" vs Butler: Design Boundaries

**What we take from "Her":**
- Voice as primary interface
- Remembers conversations
- Initiates when helpful
- Personality that adapts
- Feels present (not just responsive)

**What we explicitly reject:**
- Emotional manipulation (maximising engagement)
- Simulated romantic attachment
- Data harvesting disguised as "learning"
- Always-listening without consent
- Making it hard to leave/disable

**The Circle difference:** Butler is transparent. "I noticed X because you told me" not "I know you so well." Butler can be fully disabled in Settings. Conversation history can be deleted. No cloud backup of conversations. No engagement metrics. No retention hooks.

---

## Verification

1. **Voice chat:** Speak → see transcription → hear response. <3 second round trip on Tier 2 phone.
2. **Watch offload:** Button press → speak → hear response from watch speaker. <4 seconds including BLE.
3. **Memory:** Close app → reopen → "What did we discuss?" → Butler references summary.
4. **Personality:** Switch to Elder mode → voice slows down, language simplifies.
5. **Proactive:** Wait for load shedding trigger → Butler notification appears + speaks.
6. **isiZulu:** Say "Ngicela ibhalansi yami" → Butler responds with balance in isiZulu.
7. **Privacy:** Factory reset → all conversation data gone. No cloud recovery possible.
