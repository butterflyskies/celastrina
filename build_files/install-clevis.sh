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
