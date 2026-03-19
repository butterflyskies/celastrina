<p align="center">
  <img src="build_files/celastrina-logo.svg" alt="Celastrina logo" width="128">
</p>

# Celastrina

Custom [Bazzite](https://bazzite.gg/) images for my personal machines, built on Fedora Atomic/OSTree. Named after [*Celastrina*](https://en.wikipedia.org/wiki/Celastrina), the azure butterfly genus.

Formerly `butterfly-ublue` — see [butterflysky/butterfly-ublue](https://github.com/butterflysky/butterfly-ublue) for the archived original.

## Images

### Desktop (`celastrina`)

Based on `bazzite-nvidia-open:stable`. Targets my desktop with NVIDIA GPUs (open kernel modules
from the base image). Includes Hyprland, Ceph client, observability tools, and more.

```
ghcr.io/butterflyskies/celastrina:latest
```

### Laptop (`celastrina-laptop`)

Based on `bazzite:stable` (no NVIDIA drivers). Targets the **Lenovo Yoga 9 2-in-1 14ILL10**:

- Intel Core Ultra 7 258V (Lunar Lake)
- Intel Xe/Arc 140V integrated graphics
- 2-in-1 convertible with touchscreen and stylus support

Includes Intel VA-API acceleration, ISH/audio firmware from the Windows
extraction, power management, and sensor support for auto-rotation.

```
ghcr.io/butterflyskies/celastrina-laptop:latest
```

**Kernel requirement:** Lunar Lake needs kernel 6.12+. Bazzite stable currently ships a
sufficiently recent kernel.

## Building Locally

### Desktop

```bash
just build
```

### Laptop

Firmware files must be staged before building (see `build_files/firmware/README.md`):

```bash
cp -a /mnt/docker-swarm-volumes/firmware/yoga9-14ill10/* build_files/firmware/
just build-laptop
```

### Bootable ISOs

```bash
just build-iso          # Desktop ISO
just build-iso-laptop   # Laptop ISO
```

## Lint & Format

```bash
just lint    # shellcheck
just format  # shfmt
```

## License

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
- MIT License ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.
