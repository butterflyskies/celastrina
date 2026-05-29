#!/bin/bash
set -ouex pipefail

# Regenerate initramfs AFTER all dracut config files and modules are in place.
# --add modules whose check() returns 255 (need explicit inclusion):
#   ostree  — required for ostree-based boot
#   clevis  — LUKS auto-unlock via Tang/TPM2
#   fido2   — FIDO2 security key LUKS unlock

kver=$(cd /usr/lib/modules && echo *)
dracut -vf --no-hostonly --reproducible --zstd \
  --add "ostree clevis fido2" \
  "/usr/lib/modules/$kver/initramfs.img" "$kver"

chmod 0600 "/usr/lib/modules/$kver/initramfs.img"
