#!/bin/bash
# Generates all 10 feature pages from a template
PAGES=(
  "butler:🤖:Butler AI:AI that lives on your phone. Not in the cloud.:Every AI assistant sends your data to servers. Your questions, your voice, your life — uploaded and stored.:Butler runs entirely on your device. Your conversations never leave your phone. No internet required.:Butler uses efficient AI models (Qwen) optimised for mobile hardware. It understands questions, helps you write, and gets smarter over time — all locally.:Private (no cloud)|Fast (no network delay)|Offline (works without internet)|Free (no subscription):Qwen models. 5 device tiers (0.5B–14B). Context-aware personality modes. On-device speech recognition."
  "titanium:💳:Titanium:Tap to pay. Even without internet.:Digital payments need internet. When the network is down or data is expensive, you are stuck.:SDPKT Titanium is a hardware-grade wallet built into Circle OS. Tap phone-to-phone to send Shongololo. No internet needed.:Your phone becomes a wallet. Tap another Circle OS phone to send or receive. Transactions sync when you are back online.:Offline (NFC tap-to-pay)|Secure (TEE hardware protection)|Protected (stress detection + location rules)|Free (no transaction fees):Hardware keystore. Passive duress mode. Mesh settlement queue. SDPKT protocol."
  "mesh:📡:Mesh Network:When the network goes down the mesh stays up.:No signal? No internet? Traditional phones are useless without infrastructure.:Circle OS devices form a mesh network. Messages hop from phone to phone until they arrive. No tower needed.:Every Circle OS device is a node. When you send a message, nearby devices relay it. One person with internet connects everyone.:Works offline|Community-powered|Encrypted end-to-end|Shares OS updates too:WiFi Direct. Bluetooth LE. mDNS. Store-and-forward. 5-hop TTL. ChaCha20-Poly1305 encryption."
  "security:🔒:Security:Every file scanned. Every threat stopped.:Malware, spyware, zero-click attacks. Your phone is constantly under threat.:Circle OS has a File DMZ. Every file that enters your phone is scanned, rebuilt, and verified before you can open it.:Files enter quarantine. The DMZ strips malicious code, rebuilds the file clean, and releases it. You never touch the dangerous original.:Zero-click protection|Automatic|Malware jail for threats|Community defence sharing:CDR (Content Disarm and Reconstruction). Traffic Lobby. Malware Jail. DataAcuity integration. Behavioral sandbox."
  "dual-boot:⇄:Dual Boot:Keep your banking apps. Gain everything else.:Android or iOS — you have to choose. Privacy or your banking apps. Not both.:Circle OS supports dual boot. Slot A keeps original Android. Slot B is Circle OS. Reboot to switch. Zero risk.:Your phone gets two slots. Slot A has everything familiar — banking, work, Google. Slot B has Circle OS — private, fast, offline-ready.:No compromises|Zero risk|Instant switching|Both worlds:A/B partition scheme. Separate storage per slot. No cross-slot access."
  "compression:🗜️:Compression:Use less data. Automatically.:Data is expensive. Every photo, every download eats your budget.:Circle OS compresses everything automatically. Photos, documents, videos — smaller files, same quality, less data used.:The compression engine runs in the DMZ. Files are optimised on the way in and out. You do not notice the difference, but your data bill does.:40–70% smaller files|No visible quality loss|Automatic|Saves storage too:MozJPEG. AVIF. ZSTD. Context-aware quality tiers. Lossless for documents."
  "modes:🎭:Modes:20 modes. One phone. Always right.:Your phone does not know when you are working, sleeping, or in danger. It behaves the same all the time.:Personality modes adapt Circle OS to your context. Work mode silences distractions. Sleep mode goes dark. Secure mode locks down everything.:Choose a mode manually or let Butler detect your context. Each mode adjusts notifications, privacy, features, and appearance.:Context-aware|Battery optimised|Privacy adjustable|One tap to switch:20 built-in modes. Butler context detection. Per-mode privacy settings. Scheduled mode switching."
  "slepton:📦:SleptOn:Apps without the App Store baggage.:App stores track you, push ads, and take 30% from developers. Sideloading is risky.:SleptOn is the Circle OS app store. Curated apps, no tracking, no bloat. Pay with Titanium. Share apps via mesh.:Browse apps, tap install. No Google account. Updates come automatically. Nearby Circle devices can share apps peer-to-peer.:No tracking|FOSS-first|Titanium payments|Mesh sharing:DMZ app scanning. Attributed FOSS. Delta updates. Offline mesh distribution."
  "updates:🔄:Updates:Updates that don't eat your data.:OS updates are huge. On expensive data, people skip them. Security suffers.:Circle OS uses delta updates (only what changed) and mesh distribution (download from nearby devices). Updates are 90% smaller.:When an update is available, Circle OS checks if nearby devices have it. If so, download locally for free. Otherwise, download just the changes.:90% smaller|Mesh sharing|WiFi-only option|Seamless install:Delta updates (bsdiff). A/B partitions (seamless). SleptOn OTA. Mesh chunk distribution."
  "privacy:🛡️:Privacy:No Google. No tracking. Your data stays yours.:Every app on stock Android is a potential tracker. Google, Meta, advertisers — your phone is a surveillance device by default.:Circle OS has a built-in privacy engine. Default-deny internet. Identifier spoofing. Automatic permission revoke. File DMZ.:New apps get no internet access. Every fake ID given to trackers. Permissions unused for 7 days are revoked. Files sanitised before you open them.:No Google|Default-deny internet|Identifier spoofing|Auto-revoke permissions:NetworkPermissionEnforcer. FakeResponseProvider. AutoRevokeJobService. PrivacyLogger."
)

TEMPLATE='<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>TITLE — Circle OS Features</title>
<link rel="stylesheet" href="/css/features.css"/>
</head>
<body>
<nav class="nav">
  <a href="https://circleos.co.za" class="logo">◯ Circle OS</a>
  <a href="https://circleos.co.za/waitlist" class="btn-join">Join Waitlist</a>
</nav>
<div class="page-hero">
  <div class="label">ICON CATEGORY</div>
  <h1>HERO</h1>
</div>
<div class="problem"><h2>The problem</h2><p>PROBLEM</p></div>
<div class="solution"><h2>The solution</h2><p>SOLUTION</p></div>
<div class="benefits"><h2>How it works</h2><p>HOW</p>
  <h2 style="margin-top:20px;">Benefits</h2>
  <ul>BENEFITS_LIST</ul>
</div>
<div class="technical">
  <details><summary>Technical details</summary><p style="margin-top:12px;color:#8892A4;">TECH</p></details>
</div>
<div class="cta-section">
  <a href="https://circleos.co.za/waitlist" class="btn-cta">Join the Waitlist</a>
  <p style="margin-top:12px;color:#8892A4;"><a href="https://docs.circleos.co.za">View documentation →</a></p>
</div>
<footer><p>◯ Circle OS — <a href="https://circleos.co.za">circleos.co.za</a> — Made in South Africa</p></footer>
</body>
</html>'

for page in "${PAGES[@]}"; do
  IFS=':' read -r slug icon cat hero problem solution how benefits tech <<< "$page"
  benefits_list=""
  IFS='|' read -ra BLIST <<< "$benefits"
  for b in "${BLIST[@]}"; do benefits_list+="<li>$b</li>"; done
  html="${TEMPLATE//TITLE/$cat}"
  html="${html//ICON/$icon}"
  html="${html//CATEGORY/$cat}"
  html="${html//HERO/$hero}"
  html="${html//PROBLEM/$problem}"
  html="${html//SOLUTION/$solution}"
  html="${html//HOW/$how}"
  html="${html//BENEFITS_LIST/$benefits_list}"
  html="${html//TECH/$tech}"
  mkdir -p "pages/$slug"
  echo "$html" > "pages/$slug/index.html"
  echo "Generated: pages/$slug/index.html"
done
