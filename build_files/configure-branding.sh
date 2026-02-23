#!/bin/bash

set -ouex pipefail

###############################################################################
# Celastrina distro branding
# Overrides Bazzite's KDE "About this System" / GNOME "About" info
###############################################################################

# Variant is set by the calling build script via CELASTRINA_VARIANT env var.
# Falls back to detecting NVIDIA drivers if not set.
if [ -z "${CELASTRINA_VARIANT:-}" ]; then
	if rpm -q akmod-nvidia &>/dev/null || rpm -q kmod-nvidia &>/dev/null; then
		CELASTRINA_VARIANT="NVIDIA Edition"
	else
		CELASTRINA_VARIANT="Desktop"
	fi
fi

# KDE About System
mkdir -p /etc/xdg
cat >/etc/xdg/kcm-about-distrorc <<EOF
[General]
LogoPath=/usr/share/pixmaps/system-logo-white.png
Name=Celastrina
Website=https://github.com/butterflyskies/celastrina
Variant=${CELASTRINA_VARIANT}
EOF

echo "Configured Celastrina branding (Variant: ${CELASTRINA_VARIANT})"
