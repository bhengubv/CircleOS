# Amarula — Build

Everything needed to go from "fresh WSL2 Ubuntu" to "Amarula image boots in rk3568 emulator."

## Order

1. `setup.sh` — installs OH build dependencies in WSL2 Ubuntu 22.04/24.04. Run once.
2. `sync.sh` — `repo init` + `repo sync` the OH 6.1 source tree (~45GB, overnight first time).
3. `overlay.sh` — copies Amarula's `productdefine/` + `vendor/circle/` into the OH tree.
4. `build.sh` — runs OH's `./build.sh --product-name amarula --ccache --no-prebuilt-sdk`. 4–8h first, minutes after.

## Where the OH source tree lives

`~/ohos/` inside WSL2 Ubuntu. **Never on `/mnt/c/`** — the 9P filesystem makes it 5–10× slower.

## Flags worth knowing

- `--ccache` — compilation cache. Massive wins on rebuilds.
- `--fast-rebuild` — skips preloader/loader/gn; goes straight to ninja. Use when only code changed.
- `--build-target <component>` — partial build of one component.

## Typical dev loop (after first full build)

```
# Change Circle mesh service
cd ~/ohos && hb build circle_mesh
# Takes minutes; output flashes to emulator
```

## Apps side

Apps (in `../apps/`) are built separately with DevEco Studio on Windows — no WSL2 needed. They produce `.hap` bundles that get baked into the image per `../vendor/circle/amarula/install_list.json`.
