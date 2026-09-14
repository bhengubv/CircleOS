# Copy the canonical mesh crypto from CircleMessages into Butler's package.
# Run from vendor/circle/apps.
for fn in ("MeshCrypto.java", "DoubleRatchet.java", "SealEnvelope.java", "KeyVault.java"):
    src = "CircleMessages/src/za/co/circleos/messages/" + fn
    dst = "Butler/src/za/co/circleos/butler/" + fn
    t = open(src, encoding="utf-8").read()
    t = t.replace("package za.co.circleos.messages;", "package za.co.circleos.butler;", 1)
    open(dst, "w", encoding="utf-8").write(t)
print("repackaged MeshCrypto + DoubleRatchet into Butler")
