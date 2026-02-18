# App Submission Guide

Publish your app to the SleptOn app store and reach Circle OS users across Africa and beyond.

---

## Before you start

- Your APK must target **Android 14 (API 34)** or higher
- Apps must not contain Google Firebase, AdMob, or other Google tracking SDKs
- Apps must not call home to third-party analytics services without user consent
- Review the [Privacy Policy for Developers](https://dev.circleos.co.za/privacy)

---

## Step 1 — Create a developer account

1. Go to [dev.circleos.co.za](https://dev.circleos.co.za)
2. Click **Register**
3. Verify your email
4. Optionally: add banking details for paid app revenue

Your developer account is free. SleptOn takes **15%** of paid app revenue (85% to you).

---

## Step 2 — Generate a signing key

If you don't have a signing key yet:

```bash
keytool -genkeypair \
  -v \
  -keystore my-release.jks \
  -alias my-key \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

Sign your APK:
```bash
# Android Studio: Build → Generate Signed Bundle/APK
# Or command line:
apksigner sign \
  --ks my-release.jks \
  --ks-key-alias my-key \
  --out my-app-release.apk \
  my-app-unsigned.apk
```

---

## Step 3 — Submit your app

### Via the developer portal

1. Log in to [dev.circleos.co.za](https://dev.circleos.co.za)
2. **My Apps → Submit new app**
3. Fill in:
   - App name and package name
   - Category (utilities, productivity, social, games, tools, education, other)
   - Short description (140 chars) and full description (Markdown)
   - Price (0 for free, or ₷ amount)
   - Source code URL (optional but improves privacy score)
4. Upload:
   - APK file
   - Icon (PNG, 512×512)
   - Screenshots (PNG, 1280×720, up to 8)
5. Click **Submit for review**

### Via the API

```bash
curl -X POST https://api.slepton.co.za/api/developer/apps \
  -H "Authorization: Bearer <your-dev-token>" \
  -F "apk=@my-app-release.apk" \
  -F "icon=@icon.png" \
  -F "name=My App" \
  -F "description=A great app" \
  -F "category=utilities" \
  -F "price_sdpkt=0"
```

---

## Step 4 — Automated scan

After submission, SleptOnAPI runs automated checks:

| Check | What it looks for |
|-------|------------------|
| **Signature** | Valid APK signature |
| **Manifest** | Dangerous permissions declared |
| **Tracker detection** | Known tracker SDK classnames (350+ signatures) |
| **Network behaviour** | Whether the app phones home during sandbox run |
| **Malware** | SHA-256 against known-bad list |
| **Privacy score** | Computed 0–100 |

You'll receive the scan results via email within 5 minutes.

---

## Step 5 — Review

| Privacy score | Review path |
|---------------|------------|
| 70–100 | Automated — published within 30 min |
| 40–69 | Human review — 48 hours |
| 0–39 | Human review — 7 days; may be rejected |

You can view review status in the developer portal.

---

## Updating your app

1. Upload a new APK with a higher `versionCode`
2. The update goes through the same scan process
3. Users receive the update through:
   - OTA-style update notification in SleptOn
   - Mesh distribution (if nearby phones have the update)

---

## Revenue and payments

- SleptOn pays out weekly to your registered bank account or Titanium Wallet
- Minimum payout: ₷50
- Currency: ZAR (South African Rand) or ₷ Shongololo
- Tax: developers are responsible for their own tax obligations

---

## App listing guidelines

**Do:**
- Describe what your app actually does
- Use real screenshots of your app (not mockups)
- List all permissions your app uses and why

**Do not:**
- Claim features the app doesn't have
- Use misleading category tags
- Submit apps that mimic system apps to deceive users
- Submit apps with hidden functionality

Violations result in removal and may result in account suspension.

---

## Getting help

- Developer Discord: [discord.gg/circleos-dev](https://discord.gg/circleos)
- Email: dev@thegeek.co.za
- Docs: [dev.circleos.co.za/docs](https://dev.circleos.co.za/docs)
