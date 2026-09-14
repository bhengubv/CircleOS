package com.circleos.server.mesh;

import java.util.Arrays;

public class MeshRouterTest {
    static int passed = 0, failed = 0;
    static void check(boolean c, String l) {
        if (c) passed++; else { failed++; System.out.println("FAIL: " + l); }
    }

    public static void main(String[] a) {
        System.out.println("java: " + System.getProperty("java.version"));
        byte[] me = MeshRouter.idToBytes("0011223344556677");
        byte[] other = MeshRouter.idToBytes("8899aabbccddeeff");
        byte[] payload = "CE2:hello-mesh".getBytes();

        MeshRouter r = new MeshRouter(100);
        byte[] f = r.encode(other, me, 5, payload);
        MeshRouter.Parsed p = r.decode(f);
        check(p != null, "decode ok");
        check(p.ver == 3 && p.ttl == 5 && p.hop == 0, "header fields");
        check(Arrays.equals(p.payload, payload), "payload roundtrip");
        check(Arrays.equals(p.dst, other) && Arrays.equals(p.src, me), "dst/src roundtrip");

        check(r.route(p, me) == MeshRouter.Decision.RELAY, "relay for another node");
        check(r.route(r.decode(f), me) == MeshRouter.Decision.DROP, "duplicate dropped (dedup)");

        MeshRouter r2 = new MeshRouter(100);
        check(r2.route(r2.decode(r2.encode(me, other, 5, payload)), me)
                == MeshRouter.Decision.DELIVER, "deliver when addressed to me");

        MeshRouter r3 = new MeshRouter(100);
        MeshRouter.Parsed pb = r3.decode(r3.encode(null, other, 5, payload));
        check((pb.flags & MeshRouter.FLAG_BROADCAST) != 0, "broadcast flag set");
        check(r3.route(pb, me) == MeshRouter.Decision.DELIVER, "deliver broadcast");

        MeshRouter r4 = new MeshRouter(100);
        check(r4.route(r4.decode(r4.encode(other, me, 1, payload)), me)
                == MeshRouter.Decision.DROP, "TTL-exhausted dropped");

        MeshRouter r5 = new MeshRouter(100);
        MeshRouter.Parsed p5 = r5.decode(r5.encode(other, me, 5, payload));
        MeshRouter.Parsed pr = r5.decode(r5.reframeForRelay(p5));
        check(pr.hop == 1, "reframe increments hop");
        check(Arrays.equals(pr.msgId, p5.msgId), "reframe keeps msgId (loop-safe)");
        check(Arrays.equals(pr.payload, payload), "reframe keeps payload");

        check("0011223344556677".equals(MeshRouter.bytesToId(me)), "id <-> bytes");

        System.out.println("passed=" + passed + " failed=" + failed);
        if (failed > 0) System.exit(1);
        System.out.println("ALL GREEN");
    }
}
