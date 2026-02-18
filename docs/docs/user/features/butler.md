# Butler AI

Butler is Circle OS's on-device AI assistant. It runs entirely on your phone — no internet required, no data sent to servers.

---

## How to use Butler

Tap the **Butler** icon in the app drawer or swipe from the right edge of the screen.

**You can ask Butler:**

- General questions: "What's the capital of Mozambique?"
- Writing help: "Help me write a professional email declining a meeting"
- Reminders: "Remind me to take medication at 8 AM every day"
- Calculations: "What's 15% of R3,450?"
- Device tasks: "Turn on Do Not Disturb for 2 hours"

---

## Device tiers

Butler automatically selects the right AI model for your phone's hardware:

| Tier | RAM | Model | Quality |
|------|-----|-------|---------|
| 1 | < 3 GB | Qwen 0.5B | Basic responses |
| 2 | 3–4 GB | Qwen 1.5B | Good responses |
| 3 | 4–6 GB | Qwen 3B | Very good |
| 4 | 6–8 GB | Qwen 7B | Excellent |
| 5 | 8 GB+ | Qwen 14B | Near-desktop quality |

---

## Privacy

- All conversations stay on your device.
- No audio is sent anywhere — ever.
- Conversation history is stored locally and encrypted.
- Butler has no internet access by default.

---

## Personality modes

Butler adapts to your [Personality Mode](modes.md):

- **Standard mode:** Balanced, helpful assistant
- **Private mode:** No conversation history saved
- **Work mode:** Professional tone, calendar integration
- **Sleep mode:** Butler is silent — no notifications

---

## Voice input

Butler supports local voice input via the on-device speech recogniser. Enable in:

**Circle Settings → Butler → Voice Input → Enable**

Voice audio is processed locally and immediately discarded.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Butler very slow | Your device is Tier 1 — responses take longer. Normal. |
| Butler says it can't help | Rephrase your question — it may be out of scope for the current model |
| Butler stopped working | Settings → Butler → Clear Cache |
