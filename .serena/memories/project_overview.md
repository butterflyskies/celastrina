# Celastrina — Project Overview

## Purpose
Custom Bazzite/Fedora Atomic OSTree images for personal machines. Two variants:
- **celastrina** (desktop) — `bazzite-nvidia-open:stable`, NVIDIA GPUs, Hyprland, Ceph client
- **celastrina-laptop** — `bazzite:stable` (no NVIDIA), Lenovo Yoga 9 2-in-1 14ILL10 (Intel Lunar Lake, Xe/Arc 140V), touchscreen, stylus, auto-rotation

## Key Files
- `Containerfile` — desktop image build
- `Containerfile.laptop` — laptop image build (Intel VA-API, ISH audio firmware, power mgmt, sensors)
- `Justfile` — all build recipes
- `install-laptop.sh` — standalone LUKS2+btrfs bootc installer for the laptop
- `build_files/` — branding, firmware staging area
- `disk_config/` — BIB config TOML files for ISO/qcow2 builds
- `netboot/` — PXE/iPXE kickstart for laptop

## Build Commands
```bash
just build              # Desktop image
just build-laptop       # Laptop image (requires firmware staged in build_files/firmware/)
just build-iso          # Desktop ISO via BIB
just build-iso-laptop   # Laptop ISO via BIB
just lint               # shellcheck all .sh files
just format             # shfmt all .sh files
```

## Key Issues
- #5: Laptop post-install fixes (LUKS naming, iwlwifi panic, Tang, EFI label, installer improvements)
- #8: Rebrand image from Bazzite to Celastrina (os-release, image-info.json, MOTD)

## Branding
`configure-branding.sh` handles all downstream branding:
- KDE About System (`/etc/xdg/kcm-about-distrorc`)
- `/usr/share/ublue-os/image-info.json` (ublue-motd, fastfetch)
- `/usr/share/ublue-os/motd/celastrina.md` (replaces bazzite.md, patches `/usr/libexec/ublue-motd`)
- `/usr/lib/os-release` (sed patches in-place, preserves upstream fields)
- Desktop defaults to `CELASTRINA_IMAGE_NAME=celastrina`; laptop passes `celastrina-laptop`

## Laptop Hardware Notes
- iwlwifi_mld (Intel BE201 WiFi 7) causes kernel panic on Yoga 9 — blacklisted in image
- LUKS boot fix: use `rd.luks.name=<UUID>=luks-root` instead of `rd.luks.uuid` (karg, not image change)
- Kernel cmdline managed via `rpm-ostree kargs` on installed system

## Tech Stack
- Bash scripts (Justfile recipes, installer)
- Podman / Bootc Image Builder (BIB)
- git-crypt for encrypted firmware blobs
- GitHub Actions CI
