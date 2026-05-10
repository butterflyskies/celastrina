#!/bin/bash

set -ouex pipefail

###############################################################################
# Thunderbolt / USB4 early-boot support
# Adds thunderbolt controller driver to initrd so NVMe storage and docks
# behind Thunderbolt ports are available before root is mounted.
###############################################################################

install -Dm644 /dev/stdin /usr/lib/dracut/dracut.conf.d/thunderbolt.conf <<'EOF'
# Thunderbolt/USB4 controller + USB HID — needed for keyboard/storage through TB docks
force_drivers+=" thunderbolt thunderbolt-net usb_storage xhci-pci xhci-hcd usbhid "
EOF
