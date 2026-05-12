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

# Auto-authorize Thunderbolt devices in initrd so dock peripherals (keyboard)
# are available for LUKS passphrase entry. bolt takes over after root mounts.
install -Dm644 /dev/stdin /usr/lib/dracut/dracut.conf.d/thunderbolt-authorize.conf <<'EOF'
install_items+=" /usr/lib/udev/rules.d/99-thunderbolt-initrd-authorize.rules "
EOF

install -Dm644 /dev/stdin /usr/lib/udev/rules.d/99-thunderbolt-initrd-authorize.rules <<'EOF'
ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
EOF
