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

# Blacklist iwlwifi_mld — Intel BE201 WiFi 7 driver causes kernel panic on
# Lunar Lake during driver init. Regular iwlwifi works fine as fallback.
# See: https://github.com/butterflyskies/celastrina/issues/5#2
echo 'blacklist iwlwifi_mld' > /usr/lib/modprobe.d/blacklist-iwlwifi-mld.conf
