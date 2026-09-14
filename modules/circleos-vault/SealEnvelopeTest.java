// Standalone unit test for SealEnvelope — pure JDK, software AES key in place of
// the Android Keystore key. Run:
//   javac za/co/circleos/messages/SealEnvelope.java SealEnvelopeTest.java && java SealEnvelopeTest
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;

public class SealEnvelopeTest {

    static int passed = 0, failed = 0;
    static void check(boolean c, String label) {
        if (c) passed++; else { failed++; System.out.println("FAIL: " + label); }
    }

    // SealEnvelope is package-private; reach it via reflection so the test can live
    // outside the package (it only needs to prove the round-trip).
    static String seal(SecretKey k, String s) throws Exception {
        java.lang.reflect.Method m = Class.forName("za.co.circleos.messages.SealEnvelope")
                .getDeclaredMethod("sealWith", SecretKey.class, String.class);
        m.setAccessible(true);
        return (String) m.invoke(null, k, s);
    }
    static String unseal(SecretKey k, String s) throws Exception {
        java.lang.reflect.Method m = Class.forName("za.co.circleos.messages.SealEnvelope")
                .getDeclaredMethod("unsealWith", SecretKey.class, String.class);
        m.setAccessible(true);
        return (String) m.invoke(null, k, s);
    }
    static boolean isSealed(String s) throws Exception {
        java.lang.reflect.Method m = Class.forName("za.co.circleos.messages.SealEnvelope")
                .getDeclaredMethod("isSealed", String.class);
        m.setAccessible(true);
        return (Boolean) m.invoke(null, s);
    }

    public static void main(String[] args) throws Exception {
        System.out.println("java: " + System.getProperty("java.version"));
        KeyGenerator kg = KeyGenerator.getInstance("AES");
        kg.init(256);
        SecretKey k = kg.generateKey();

        // 1) Round-trip a realistic payload (a base64 PKCS8 private key blob).
        String secret = java.util.Base64.getEncoder().encodeToString(new byte[48]);
        secret = secret + "Xy9+/abcDEF0123456789=="; // mixed chars
        String sealed = seal(k, secret);
        check(sealed != null && sealed.startsWith("V1:"), "seal -> V1 envelope");
        check(isSealed(sealed), "isSealed true for V1");
        check(!isSealed(secret), "isSealed false for plaintext");
        String back = unseal(k, sealed);
        check(secret.equals(back), "round-trip restores plaintext (got=" + back + ")");

        // 2) Distinct IV each time -> same plaintext seals to different ciphertext.
        String s2 = seal(k, secret);
        check(!sealed.equals(s2), "fresh IV per seal");
        check(secret.equals(unseal(k, s2)), "second envelope also opens");

        // 3) Wrong key cannot open it.
        KeyGenerator kg2 = KeyGenerator.getInstance("AES"); kg2.init(256);
        SecretKey other = kg2.generateKey();
        check(unseal(other, sealed) == null, "wrong key rejected");

        // 4) Tamper: flip a byte in the ciphertext -> GCM tag fails.
        char[] cc = sealed.toCharArray();
        int i = cc.length - 4;
        cc[i] = (cc[i] == 'A') ? 'B' : 'A';
        check(unseal(k, new String(cc)) == null, "tampered envelope rejected");

        // 5) Empty string round-trips.
        String e = seal(k, "");
        check("".equals(unseal(k, e)), "empty string round-trips");

        System.out.println("passed=" + passed + " failed=" + failed);
        if (failed > 0) System.exit(1);
        System.out.println("ALL GREEN");
    }
}
