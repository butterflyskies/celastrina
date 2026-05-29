#!/bin/bash

set -ouex pipefail

###############################################################################
# Clevis — automated LUKS unlocking via Tang (network-bound disk encryption)
#
# Packages:
#   clevis-luks     — LUKS2 integration for clevis
#   clevis-dracut   — dracut module to unlock at early boot
#   clevis-systemd  — systemd units for non-root LUKS volumes
#   clevis-pin-tpm2 — TPM2 pin (for future sss/hybrid policies)
###############################################################################

dnf5 install -y \
  clevis-luks \
  clevis-dracut \
  clevis-systemd \
  clevis-pin-tpm2

# Regenerate initramfs with the clevis dracut module so early-boot unlock works.
# The ostree module is also required for booting ostree-based systems.
kver=$(cd /usr/lib/modules && echo *)
dracut -vf --no-hostonly --reproducible --zstd \
  --add "ostree clevis" \
  "/usr/lib/modules/$kver/initramfs.img" "$kver"
