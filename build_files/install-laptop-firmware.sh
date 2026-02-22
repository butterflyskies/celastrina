#!/bin/bash

set -ouex pipefail

###############################################################################
# Laptop firmware installation — Lenovo Yoga 9 2-in-1 14ILL10 (Lunar Lake)
#
# Firmware files must be staged into build_files/firmware/ BEFORE building.
# They are extracted from the laptop's Windows installation and are proprietary
# blobs that cannot be committed to git.
#
# Expected layout in the build context (/ctx/firmware/):
#   ish/*.bin         — Intel Sensor Hub firmware
#   audio/            — Audio topology/firmware files (preserves subdirectory structure)
#
# The firmware staging directory on the build host is:
#   /mnt/docker-swarm-volumes/firmware/yoga9-14ill10/
#
# Copy firmware into build_files/firmware/ before running the build:
#   cp -a /mnt/docker-swarm-volumes/firmware/yoga9-14ill10/* build_files/firmware/
###############################################################################

# --- Intel Sensor Hub (ISH) firmware ---
if [ -d /ctx/firmware/ish ]; then
	mkdir -p /usr/lib/firmware/intel/ish
	cp /ctx/firmware/ish/*.bin /usr/lib/firmware/intel/ish/
	echo "Installed ISH firmware"
else
	echo "WARNING: No ISH firmware found at /ctx/firmware/ish — skipping"
fi

# --- Audio firmware (SOF topology files, etc.) ---
if [ -d /ctx/firmware/audio ]; then
	cp -a /ctx/firmware/audio/. /usr/lib/firmware/
	echo "Installed audio firmware"
else
	echo "WARNING: No audio firmware found at /ctx/firmware/audio — skipping"
fi

# --- SOF (Sound Open Firmware) package ---
rpm -q sof-firmware || dnf5 install -y sof-firmware

# --- Intel VA-API hardware video acceleration ---
dnf5 install -y intel-media-driver

# --- IIO Sensor Proxy (accelerometer / auto-rotation) ---
dnf5 install -y iio-sensor-proxy

# NOTE: Kernel 6.12+ is required for full Lunar Lake support. Bazzite stable
# currently ships a sufficiently recent kernel. If the base image ever pins to
# an older kernel, this will need a kernel override or pin to >= 6.12.
