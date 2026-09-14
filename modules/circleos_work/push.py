#!/usr/bin/env python3
"""Push CircleOS telemetry SA + launcher files via paramiko jump host."""
import os
import sys
import paramiko

JUMP_HOST = '197.97.200.106'
JUMP_USER = 'geektrading'
JUMP_PASS = 'j82T8KpBB![*]wiG91054zlJ(M%l9:2x'
TARGET_HOST = '197.97.200.201'
TARGET_USER = 'geektrading'
TARGET_PASS = 'HFe76=U83:=P10u!37C6"zhn5T(H)HpJ'

BASE = '/home/geektrading/ohos/vendor/circle/amarula/circleos'

LOCAL = r'C:\Dev\Solutions\com.bhengubv\circleos_work'

FILES = [
    (os.path.join(LOCAL, 'circleos_telemetry_service.cpp'),
     f'{BASE}/src/circleos_telemetry_service.cpp'),
    (os.path.join(LOCAL, 'circleos_telemetry_service.cfg'),
     f'{BASE}/etc/circleos_telemetry_service.cfg'),
    (os.path.join(LOCAL, 'circleos_telemetry_service.json'),
     f'{BASE}/sa_profile/circleos_telemetry_service.json'),
    (os.path.join(LOCAL, 'main.cpp'),
     f'{BASE}/launcher/main.cpp'),
    (os.path.join(LOCAL, 'launcher_BUILD.gn'),
     f'{BASE}/launcher/BUILD.gn'),
]

def main():
    jump = paramiko.SSHClient()
    jump.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    jump.connect(JUMP_HOST, username=JUMP_USER, password=JUMP_PASS, timeout=20)

    ch = jump.get_transport().open_channel(
        'direct-tcpip', (TARGET_HOST, 22), ('127.0.0.1', 0))
    t = paramiko.SSHClient()
    t.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    t.connect(TARGET_HOST, username=TARGET_USER, password=TARGET_PASS,
              sock=ch, timeout=30)

    def run(cmd, timeout=60):
        _, o, e = t.exec_command(cmd, timeout=timeout)
        return (o.read() + e.read()).decode('utf-8', errors='replace').strip()

    # Ensure directories exist
    dirs = sorted({os.path.dirname(d) for _, d in FILES})
    for d in dirs:
        print(f"[mkdir -p] {d}")
        out = run(f"mkdir -p '{d}'")
        if out:
            print(out)

    sftp = t.open_sftp()
    for local, remote in FILES:
        print(f"[put] {local}  ->  {remote}")
        sftp.put(local, remote)

    # Verify: line count + first lines
    print("\n========== VERIFICATION ==========")
    for _, remote in FILES:
        print(f"\n--- {remote} ---")
        print(run(f"wc -l '{remote}' && head -3 '{remote}'"))

    print("\n--- UNTOUCHED FILES (for caller to merge) ---")
    print(run(f"ls -la '{BASE}/BUILD.gn' '{BASE}/sa_profile/BUILD.gn' "
              f"/home/geektrading/ohos/vendor/circle/amarula/ohos.build "
              f"/home/geektrading/ohos/build/compile_standard_whitelist.json 2>&1"))

    sftp.close()
    t.close()
    jump.close()
    print("\n[done]")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"FAIL: {e}", file=sys.stderr)
        sys.exit(1)
