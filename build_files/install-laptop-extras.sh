#!/bin/bash

set -ouex pipefail

###############################################################################
# Laptop extras — 2-in-1 / touchscreen / power management packages
# Target: Lenovo Yoga 9 2-in-1 14ILL10 (Intel Lunar Lake)
#
# Already in bazzite:stable (no need to install):
#   libwacom, libinput, thermald, iio-sensor-proxy
###############################################################################

# Power management — power-profiles-daemon for Lunar Lake P-state integration
dnf5 install -y power-profiles-daemon

# Keyboard backlight control
dnf5 install -y brightnessctl
