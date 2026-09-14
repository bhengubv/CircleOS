// Standalone unit test for DoubleRatchet — pure JCA, no Android. Run off-device:
//   javac za/co/circleos/messages/DoubleRatchet.java RatchetSelfTest.java && java RatchetSelfTest
import za.co.circleos.messages.DoubleRatchet;
import za.co.circleos.messages.DoubleRatchet.State;

import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.PublicKey;
import java.security.spec.NamedParameterSpec;
import javax.crypto.KeyAgreement;

public class RatchetSelfTest {

    static int passed = 0, failed = 0;

    static void check(boolean cond, String label) {
        if (cond) { passed++; }
        else { failed++; System.out.println("FAIL: " + label); }
    }

    static void eq(String a, String b, String label) {
        check(a != null && a.equals(b), label + " (got=" + a + ")");
    }

    static KeyPair gen() throws Exception {
        KeyPairGenerator kpg = KeyPairGenerator.getInstance("XDH");
        kpg.initialize(NamedParameterSpec.X25519);
        return kpg.generateKeyPair();
    }

    static byte[] ecdh(java.security.PrivateKey priv, PublicKey pub) throws Exception {
        KeyAgreement ka = KeyAgreement.getInstance("XDH");
        ka.init(priv);
        ka.doPhase(pub, true);
        return ka.generateSecret();
    }

    static int lex(byte[] a, byte[] b) {
        int m = Math.min(a.length, b.length);
        for (int i = 0; i < m; i++) { int d = (a[i]&0xFF)-(b[i]&0xFF); if (d!=0) return d; }
        return a.length - b.length;
    }

    public static void main(String[] args) throws Exception {
        System.out.println("java: " + System.getProperty("java.version"));

        KeyPair idA = gen(), idB = gen();
        byte[] shA = ecdh(idA.getPrivate(), idB.getPublic());
        byte[] shB = ecdh(idB.getPrivate(), idA.getPublic());
        check(java.util.Arrays.equals(shA, shB), "ECDH symmetric");

        State a = DoubleRatchet.init(shA, idA.getPublic(), idA, idB.getPublic());
        State b = DoubleRatchet.init(shB, idB.getPublic(), idB, idA.getPublic());

        // Whoever has the lexicographically larger identity key is the initiator (holds the
        // first sending chain). The first message must come from them.
        boolean aInit = lex(idA.getPublic().getEncoded(), idB.getPublic().getEncoded()) > 0;
        State first = aInit ? a : b, second = aInit ? b : a;
        String firstName = aInit ? "A" : "B";

        check(DoubleRatchet.canSend(first), "initiator can send at init");
        check(!DoubleRatchet.canSend(second), "responder cannot send until first receive");

        // ── 1) In-order, alternating directions (exercises a DH ratchet each switch) ──
        String w, pt;
        w = DoubleRatchet.encrypt(first, "hello-1");
        check(DoubleRatchet.isRatchet(w), "envelope is CE2");
        pt = DoubleRatchet.decrypt(second, w);  eq(pt, "hello-1", "in-order msg1 " + firstName + "->peer");

        w = DoubleRatchet.encrypt(second, "reply-1");
        pt = DoubleRatchet.decrypt(first, w);   eq(pt, "reply-1", "in-order reply1");

        w = DoubleRatchet.encrypt(first, "hello-2");
        pt = DoubleRatchet.decrypt(second, w);  eq(pt, "hello-2", "in-order msg2");

        w = DoubleRatchet.encrypt(second, "reply-2");
        pt = DoubleRatchet.decrypt(first, w);   eq(pt, "reply-2", "in-order reply2");

        w = DoubleRatchet.encrypt(first, "hello-3");
        pt = DoubleRatchet.decrypt(second, w);  eq(pt, "hello-3", "in-order msg3");

        // ── 2) Unique message keys: same plaintext twice -> different ciphertext ──
        String c1 = DoubleRatchet.encrypt(second, "same");
        String c2 = DoubleRatchet.encrypt(second, "same");
        check(!c1.equals(c2), "fresh message key per message");
        eq(DoubleRatchet.decrypt(first, c1), "same", "decrypt c1");
        eq(DoubleRatchet.decrypt(first, c2), "same", "decrypt c2");

        // ── 3) Out-of-order within one sending chain (skip then catch up) ──
        // 'second' sends three more without receiving in between -> one chain.
        String o1 = DoubleRatchet.encrypt(second, "ooo-1");
        String o2 = DoubleRatchet.encrypt(second, "ooo-2");
        String o3 = DoubleRatchet.encrypt(second, "ooo-3");
        eq(DoubleRatchet.decrypt(first, o1), "ooo-1", "ooo recv 1");
        eq(DoubleRatchet.decrypt(first, o3), "ooo-3", "ooo recv 3 (skips 2)");
        eq(DoubleRatchet.decrypt(first, o2), "ooo-2", "ooo recv 2 (from skipped)");

        // ── 4) Persistence: pack/unpack mid-stream and keep going ──
        byte[] packedFirst = DoubleRatchet.pack(first);
        byte[] packedSecond = DoubleRatchet.pack(second);
        State first2 = DoubleRatchet.unpack(packedFirst);
        State second2 = DoubleRatchet.unpack(packedSecond);
        w = DoubleRatchet.encrypt(first2, "after-reload");
        pt = DoubleRatchet.decrypt(second2, w);  eq(pt, "after-reload", "survives pack/unpack");
        // and the reverse direction after reload
        w = DoubleRatchet.encrypt(second2, "reload-reply");
        pt = DoubleRatchet.decrypt(first2, w);   eq(pt, "reload-reply", "reverse after reload");

        // ── 5) Tamper rejection: flip a ciphertext byte -> must fail ──
        String good = DoubleRatchet.encrypt(first2, "secret");
        char[] cc = good.toCharArray();
        cc[cc.length - 5] = (cc[cc.length - 5] == 'A') ? 'B' : 'A';
        boolean rejected = false;
        try { DoubleRatchet.decrypt(second2, new String(cc)); } catch (Throwable t) { rejected = true; }
        check(rejected, "tampered ciphertext rejected");

        System.out.println("passed=" + passed + " failed=" + failed);
        if (failed > 0) System.exit(1);
        System.out.println("ALL GREEN");
    }
}
