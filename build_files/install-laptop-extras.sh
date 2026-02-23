#!/bin/bash

set -ouex pipefail

###############################################################################
# Laptop extras — 2-in-1 / touchscreen / power management packages
# Target: Lenovo Yoga 9 2-in-1 14ILL10 (Intel Lunar Lake)
#
# Already in bazzite:stable (no need to install):
#   libwacom, libinput, thermald, iio-sensor-proxy,
#   tuned-ppd (provides ppd-service — conflicts with power-profiles-daemon)
###############################################################################

# Keyboard backlight control
dnf5 install -y brightnessctl
