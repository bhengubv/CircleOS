# Contributing

Circle OS is open source under Apache 2.0. Contributions welcome.

---

## Where to contribute

| Area | Repo | What's needed |
|------|------|--------------|
| OS core | `CircleOS_platform_frameworks_base` | Java, C++, Rust |
| Vendor overlay | `CircleOS_vendor_circle` | Java, XML, Makefiles |
| Device support | `CircleOS_device_*` | BoardConfig, kernel |
| Docs | `CircleOS` (this repo) | Markdown |
| Backend | `thegeeknetwork` (SleptOnAPI) | C#, .NET |

---

## Branch naming

```
feature/short-description
fix/issue-number-short-description
docs/what-you-changed
device/brand-model
```

---

## Commit style

```
component: short summary (imperative, lowercase, no period)

Longer description if needed. Explain why, not what.
What is visible in the diff. Why is not.

Co-Authored-By: Your Name <email>
```

Examples:
```
privacy: add per-app clipboard access control
mesh: fix IPv6 address decoding in /proc/net/tcp6
docs: add Redmi Note 10 installation guide
```

---

## Pull request process

1. Fork the repo and create your branch from `circle-14.0-clean`.
2. Make your changes — small, focused PRs merge faster.
3. Run `mka bacon` to confirm it builds.
4. Write or update documentation for any new feature.
5. Open a PR against `circle-14.0-clean`.
6. One maintainer review required before merge.

---

## Code review criteria

- Does it build cleanly?
- Does it break any existing behaviour?
- Is it within the privacy/security principles of Circle OS?
- Is it minimal — does it only do what it needs to do?
- Is it documented?

---

## Reporting bugs

Open an issue on GitHub with:

- Device model and Circle OS version
- Steps to reproduce
- Expected vs actual behaviour
- Logcat output if available (`adb logcat | grep CircleOS`)

---

## Questions

Ask in `#dev` on [Discord](https://discord.gg/circleos).
