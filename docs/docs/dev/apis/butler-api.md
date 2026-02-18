# Butler AI API (Android)

The Butler AI API provides on-device language model inference. No internet connection required.

---

## Permissions

```xml
<uses-permission android:name="android.permission.CIRCLE_BUTLER_CHAT" />
```

---

## ButlerAI

```java
import android.circleos.butler.ButlerAI;
import android.circleos.butler.ButlerSession;
import android.circleos.butler.ButlerMessage;

ButlerAI butler = ButlerAI.getInstance(context);
```

### Check availability

```java
ButlerAI.Status status = butler.getStatus();
// READY, LOADING, UNAVAILABLE (not enough RAM), DISABLED
```

### Single-turn inference

```java
butler.ask("Summarise this email in one sentence: " + emailText,
    new ButlerAI.ResponseCallback() {
        @Override
        public void onToken(String token) {
            // streaming token — update UI
            appendToOutput(token);
        }

        @Override
        public void onComplete(String fullResponse) {
            // inference done
        }

        @Override
        public void onError(int errorCode) { }
    }
);
```

### Multi-turn session (chat)

```java
ButlerSession session = butler.createSession();
session.setPersonality(ButlerSession.PERSONALITY_FRIENDLY);
session.setContextDepth(10);  // remember last 10 turns

// Send messages
session.send(new ButlerMessage.Builder()
    .setRole(ButlerMessage.ROLE_USER)
    .setContent("What's the weather like today?")
    .build(),
    responseCallback
);

// Close when done
session.close();
```

---

## Privacy guarantees

- Butler **never uses the internet** regardless of network permission settings
- All inference runs on-device in an isolated process
- Conversation history is stored only in RAM (no persistence across sessions unless the app explicitly saves it)
- Butler cannot read your files, contacts, or other app data unless you pass the content as a message

---

## ButlerMessage

| Field | Description |
|-------|-------------|
| `role` | `ROLE_SYSTEM` / `ROLE_USER` / `ROLE_ASSISTANT` |
| `content` | Message text (UTF-8) |
| `timestamp` | When message was added |

---

## Model sizes and requirements

| Model | Min RAM | Speed | Best for |
|-------|---------|-------|---------|
| 0.5B | 2 GB | Very fast | Quick answers, autocomplete |
| 1B | 2 GB | Fast | General chat |
| 3B | 4 GB | Medium | Complex reasoning |
| 7B | 6 GB | Slower | Long documents, code |
| 14B | 12 GB | Slow | Best quality responses |

The default model is selected automatically based on available RAM. Users can override in Settings → Butler AI.

---

## Error codes

| Code | Constant | Meaning |
|------|----------|---------|
| 1 | `ERROR_UNAVAILABLE` | Not enough RAM for any model |
| 2 | `ERROR_LOADING` | Model is still loading, retry in a moment |
| 3 | `ERROR_CONTEXT_OVERFLOW` | Session context too long, start new session |
| 4 | `ERROR_PERMISSION_DENIED` | App lacks `CIRCLE_BUTLER_CHAT` permission |
| 5 | `ERROR_DISABLED` | User has disabled Butler in settings |
