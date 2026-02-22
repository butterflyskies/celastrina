#!/bin/bash

set -ouex pipefail

###############################################################################
# Laptop extras — 2-in-1 / touchscreen / power management packages
# Target: Lenovo Yoga 9 2-in-1 14ILL10 (Intel Lunar Lake)
###############################################################################

# Touchscreen and stylus support (may already be in base, dnf5 handles that)
dnf5 install -y \
	libwacom \
	libinput

# Power management — power-profiles-daemon for Lunar Lake P-state integration
dnf5 install -y power-profiles-daemon

# Intel thermal management daemon
dnf5 install -y thermald

# Keyboard backlight control
dnf5 install -y brightnessctl
