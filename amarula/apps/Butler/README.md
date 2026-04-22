# Butler

Voice-first AI assistant, baked into Amarula. Public name **B!** (pronounced "Bee"). Code name stays **Butler**.

**Bundle:** `com.circle.butler`
**Purpose:** single entrypoint for on-device inference — voice, quick actions, "what just happened" summaries.

## Status

Skeleton. Central mic + transcript stub only. No inference backend wired.

## Notes

- Inference runs on-device via llama.cpp + BitNet (port from AOSP Circle Inference Service — see existing chapter specs)
- Wake word / ASR / TTS to follow Sherpa-ONNX + Piper
- Wolverine client error reporting integrates here (Tier 1 local heal messages surface through Butler)
