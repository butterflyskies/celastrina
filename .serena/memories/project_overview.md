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

## Active Branch / PR
- Branch: `feature/laptop-lunar-lake`
- PR #2: "Add Celastrina Laptop variant for Yoga 9 2-in-1" — OPEN

## Tech Stack
- Bash scripts (Justfile recipes, installer)
- Podman / Bootc Image Builder (BIB)
- git-crypt for encrypted firmware blobs
- GitHub Actions CI
