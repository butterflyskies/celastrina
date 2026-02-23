#!/bin/bash

set -euo pipefail

###############################################################################
# Laptop firmware installation — Lenovo Yoga 9 2-in-1 14ILL10 (Lunar Lake)
#
# Firmware blobs extracted from the laptop's Windows driver packages.
# Stored in-repo encrypted via git-crypt (see .gitattributes).
#
# Source files live under build_files/firmware/ and are mapped into the
# build context at /ctx/firmware/.
#
# The following packages are already in bazzite:stable and don't need installing:
#   alsa-sof-firmware, libva-intel-media-driver, iio-sensor-proxy
###############################################################################

# --- Intel Sensor Hub (ISH) firmware ---
# Provides sensor fusion for accelerometer, gyroscope, ALS on Lunar Lake.
# The ISH HID driver (intel-ish-hid) loads firmware from /usr/lib/firmware/intel/ish/.
install -Dm644 /ctx/firmware/ish/ishS_MEU_aligned.bin /usr/lib/firmware/intel/ish/ishS_MEU_aligned.bin

# --- Intel SOF DSP firmware and libraries ---
# Proprietary DSP firmware for the Lunar Lake audio subsystem.
# These supplement the open-source alsa-sof-firmware package.
install -d /usr/lib/firmware/intel/sof
install -m644 /ctx/firmware/audio/sof/dsp_fw_release.bin           /usr/lib/firmware/intel/sof/
install -m644 /ctx/firmware/audio/sof/dsp_lib_intel_aca_release.bin /usr/lib/firmware/intel/sof/
install -m644 /ctx/firmware/audio/sof/dsp_lib_intel_wov_release.bin /usr/lib/firmware/intel/sof/
install -m644 /ctx/firmware/audio/sof/dsp_lib_nld_release.bin      /usr/lib/firmware/intel/sof/
install -m644 /ctx/firmware/audio/sof/dsp_lib_psns_release.bin     /usr/lib/firmware/intel/sof/
install -m644 /ctx/firmware/audio/sof/dsp_lib_whm_release.bin      /usr/lib/firmware/intel/sof/

# --- Dolby / Elliptic Labs DSP libraries ---
# OEM audio processing: Dolby Atmos and Elliptic ultrasonic sensing.
# Loaded by the SOF firmware at runtime for speaker tuning and proximity detection.
install -d /usr/lib/firmware/intel/sof/dolby-elliptic
install -m644 /ctx/firmware/audio/dolby-elliptic/cl_dolby_lib_lnl_lite.bin               /usr/lib/firmware/intel/sof/dolby-elliptic/
install -m644 /ctx/firmware/audio/dolby-elliptic/cl_elliptic_lib_lnl.bin                 /usr/lib/firmware/intel/sof/dolby-elliptic/
install -m644 /ctx/firmware/audio/dolby-elliptic/cl_dolby_full_lib_lnl_v119.bin          /usr/lib/firmware/intel/sof/dolby-elliptic/
install -m644 /ctx/firmware/audio/dolby-elliptic/cl_elliptic_full_lib_lnl_v119.bin       /usr/lib/firmware/intel/sof/dolby-elliptic/
install -m644 /ctx/firmware/audio/dolby-elliptic/cl_dolby_full_lib_lnl_v119_v5892.bin    /usr/lib/firmware/intel/sof/dolby-elliptic/
install -m644 /ctx/firmware/audio/dolby-elliptic/cl_elliptic_full_lib_lnl_v119_v5892.bin /usr/lib/firmware/intel/sof/dolby-elliptic/
install -m644 /ctx/firmware/audio/dolby-elliptic/cl_dolby_lib_lnl_v118_v5892.bin         /usr/lib/firmware/intel/sof/dolby-elliptic/
install -m644 /ctx/firmware/audio/dolby-elliptic/cl_elliptic_lib_lnl_v118_v5892.bin      /usr/lib/firmware/intel/sof/dolby-elliptic/
install -m644 /ctx/firmware/audio/dolby-elliptic/cl_elliptic_lib_ptl_v6092.bin           /usr/lib/firmware/intel/sof/dolby-elliptic/

echo "Installed Lunar Lake firmware: ISH (1), SOF DSP (6), Dolby/Elliptic (9)"

# NOTE: Kernel 6.12+ is required for full Lunar Lake support. Bazzite stable
# currently ships a sufficiently recent kernel. If the base image ever pins to
# an older kernel, this will need a kernel override or pin to >= 6.12.
