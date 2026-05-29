/*
 * CircleOS boot-selector init — Huawei P30 Lite / Kirin 710.
 *
 * Runs as PID 1. Decides whether to boot CircleOS or stock Huawei Android
 * based on whether Volume Up is held at boot.
 *
 *   Vol Up held       -> mount circleos_system, pivot_root, exec /init.
 *   Vol Up not held   -> exec the original Huawei /init (stashed as
 *                        /init.huawei when this ramdisk is built).
 *
 * Default action — and what happens on *any* failure of the CircleOS
 * branch — is to boot stock Android. This is the safety contract:
 * a broken selector must never prevent the user from returning to stock.
 *
 * Build: statically linked aarch64 against musl. ~50 KB binary.
 *
 * Status: v0. The CircleOS branch is a stub that intentionally fails over
 * to /init.huawei after logging — until INJECT.md is wired up and the
 * circleos_system partition actually exists. This lets us validate the
 * selector logic on a device without risking the user getting stuck in a
 * non-existent OS.
 */

#define _GNU_SOURCE
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/input.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <unistd.h>

/* ---------- tuneables ----------------------------------------------- */

/* How long (ms) we sample the Volume Up state at boot. Users typically
 * hold the key before pressing Power, so a snapshot is usually enough,
 * but we re-sample for 1.5 s so a slightly-late press still registers. */
#define POLL_TOTAL_MS    1500
#define POLL_INTERVAL_MS 100

/* Where the Huawei init lives in our injected ramdisk after build. */
#define HUAWEI_INIT      "/init.huawei"

/* Where we expect the CircleOS rootfs partition to live, set up by
 * INJECT.md. The selector does *not* create this — it only mounts it. */
#define CIRCLEOS_PART    "/dev/block/by-name/circleos_system"
#define CIRCLEOS_FSTYPE  "ext4"

/* ---------- kernel-log helper --------------------------------------- */

/* We log to /dev/kmsg so the messages survive even when stdout is gone
 * and show up in `dmesg` after the device boots into either OS. */
static void klog(const char *msg)
{
    int fd = open("/dev/kmsg", O_WRONLY);
    if (fd < 0) return;
    char buf[256];
    int n = snprintf(buf, sizeof buf, "circleos-init: %s\n", msg);
    if (n > 0) (void)!write(fd, buf, n);
    close(fd);
}

/* ---------- volume-up detection ------------------------------------- */

/* Check every /dev/input/event* device for KEY_VOLUMEUP being held using
 * the EVIOCGKEY ioctl, which returns the current key-state bitmap.
 * Returns 1 if Volume Up is held on any device, 0 otherwise. */
static int vol_up_held_now(void)
{
    DIR *d = opendir("/dev/input");
    if (!d) return 0;

    /* EVIOCGKEY needs a buffer big enough for KEY_MAX bits. */
    const unsigned long bits_per_long = sizeof(long) * 8;
    unsigned long keys[(KEY_MAX / bits_per_long) + 1];

    struct dirent *e;
    int held = 0;
    while ((e = readdir(d)) != NULL && !held) {
        if (strncmp(e->d_name, "event", 5) != 0) continue;

        char path[64];
        snprintf(path, sizeof path, "/dev/input/%s", e->d_name);

        int fd = open(path, O_RDONLY | O_NONBLOCK);
        if (fd < 0) continue;

        memset(keys, 0, sizeof keys);
        if (ioctl(fd, EVIOCGKEY(sizeof keys), keys) >= 0) {
            unsigned long word = keys[KEY_VOLUMEUP / bits_per_long];
            unsigned long mask = 1UL << (KEY_VOLUMEUP % bits_per_long);
            if (word & mask) held = 1;
        }
        close(fd);
    }
    closedir(d);
    return held;
}

/* Repeatedly poll for POLL_TOTAL_MS, returning 1 as soon as Vol Up is
 * seen held on any input device. */
static int wait_for_vol_up(void)
{
    int iterations = POLL_TOTAL_MS / POLL_INTERVAL_MS;
    for (int i = 0; i < iterations; i++) {
        if (vol_up_held_now()) return 1;
        usleep(POLL_INTERVAL_MS * 1000);
    }
    return 0;
}

/* ---------- boot paths ---------------------------------------------- */

/* Boot the original Huawei stock Android. We must never return from this. */
static void boot_huawei(char *argv[], char *envp[])
{
    klog("dispatching to stock Huawei init");
    execve(HUAWEI_INIT, argv, envp);

    /* If we reach here, the exec failed and the device cannot boot.
     * Letting PID 1 exit triggers a kernel panic, which is the correct
     * outcome — silent failure could brick the device. */
    klog("FATAL: execve(/init.huawei) failed — kernel will panic");
    while (1) pause();
}

/* Attempt to boot CircleOS. On *any* failure we fall through to the
 * Huawei path: the safety contract says we must never leave the user
 * stuck. v0 of this function always falls through after logging. */
static void boot_circleos(char *argv[], char *envp[])
{
    klog("Vol Up detected — attempting CircleOS branch");

    /* --- v0 stub --- */
    /* The real implementation will (a) mkdir /newroot, (b) mount
     * CIRCLEOS_PART there, (c) move /dev /proc /sys into it,
     * (d) pivot_root, and (e) execve("/init"). It is intentionally
     * stubbed until INJECT.md is wired up — until then we have nowhere
     * real to pivot to, and silently failing CircleOS would be worse
     * than admitting it isn't built yet. */

    if (access(CIRCLEOS_PART, F_OK) != 0) {
        klog("circleos_system partition not present — falling back to stock");
        boot_huawei(argv, envp);
        return;
    }

    klog("v0: pivot_root chain not implemented yet — falling back to stock");
    boot_huawei(argv, envp);
}

/* ---------- entry point --------------------------------------------- */

int main(int argc, char *argv[], char *envp[])
{
    (void)argc;
    klog("boot selector v0 entered as PID 1");

    if (wait_for_vol_up()) {
        boot_circleos(argv, envp);
    }
    boot_huawei(argv, envp);

    /* unreachable */
    return 0;
}
