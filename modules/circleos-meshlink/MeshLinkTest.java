// Standalone unit test for MeshLinkPrivacy — pure JCA, no Android. Run:
//   javac com/circleos/server/mesh/MeshLinkPrivacy.java MeshLinkTest.java && java MeshLinkTest
import java.lang.reflect.Method;
import java.util.UUID;

public class MeshLinkTest {
    static int passed = 0, failed = 0;
    static void check(boolean c, String label) {
        if (c) passed++; else { failed++; System.out.println("FAIL: " + label); }
    }

    static Method m(String name, Class<?>... types) throws Exception {
        Method mm = Class.forName("com.circleos.server.mesh.MeshLinkPrivacy")
                .getDeclaredMethod(name, types);
        mm.setAccessible(true);
        return mm;
    }

    public static void main(String[] a) throws Exception {
        System.out.println("java: " + System.getProperty("java.version"));
        Method uuid = m("serviceUuid", long.class);
        Method enc = m("linkEncrypt", long.class, byte[].class);
        Method dec = m("linkDecrypt", long.class, byte[].class);

        byte[] frame = "CE2:hello-mesh-frame-with-some-bytes".getBytes("UTF-8");
        long E = 20000L;

        // 1) Roundtrip
        byte[] blob = (byte[]) enc.invoke(null, E, frame);
        check(blob != null && blob.length > frame.length, "encrypt produced a blob");
        byte[] back = (byte[]) dec.invoke(null, E, blob);
        check(back != null && java.util.Arrays.equals(back, frame), "roundtrip restores frame");

        // 2) Opaque: blob shouldn't contain the cleartext prefix
        String blobStr = new String(blob, "ISO-8859-1");
        check(!blobStr.contains("CE2:"), "envelope is opaque (no cleartext prefix)");

        // 3) Fresh nonce: same frame -> different blob
        byte[] blob2 = (byte[]) enc.invoke(null, E, frame);
        check(!java.util.Arrays.equals(blob, blob2), "fresh nonce per encrypt");

        // 4) UUID rotates per epoch + is deterministic
        UUID u1 = (UUID) uuid.invoke(null, E);
        UUID u1b = (UUID) uuid.invoke(null, E);
        UUID u2 = (UUID) uuid.invoke(null, E + 1);
        check(u1.equals(u1b), "serviceUuid deterministic within an epoch");
        check(!u1.equals(u2), "serviceUuid rotates across epochs");

        // 5) Clock skew: a receiver one epoch ahead still decrypts (linkDecrypt tries E and E-1)
        byte[] skew = (byte[]) dec.invoke(null, E + 1, blob);
        check(skew != null && java.util.Arrays.equals(skew, frame), "decrypts across a 1-epoch skew");
        // ...but not two epochs ahead
        byte[] tooFar = (byte[]) dec.invoke(null, E + 2, blob);
        check(tooFar == null, "rejects a 2-epoch skew");

        // 6) Tamper -> null
        byte[] t = blob.clone();
        t[t.length - 3] ^= 0x01;
        byte[] tr = (byte[]) dec.invoke(null, E, t);
        check(tr == null, "tampered blob rejected");

        System.out.println("passed=" + passed + " failed=" + failed);
        if (failed > 0) System.exit(1);
        System.out.println("ALL GREEN");
    }
}
