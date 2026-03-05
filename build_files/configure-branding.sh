#!/bin/bash

set -ouex pipefail

###############################################################################
# Celastrina distro branding
# Overrides Bazzite's KDE "About this System" / GNOME "About" info and
# patches /usr/lib/os-release to reflect Celastrina identity.
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

# Image name for os-release (e.g. "celastrina" or "celastrina-laptop").
# Set by calling build script; defaults to "celastrina".
CELASTRINA_IMAGE_NAME="${CELASTRINA_IMAGE_NAME:-celastrina}"

# Derive VARIANT_ID from image name (celastrina, celastrina-laptop, etc.)
CELASTRINA_VARIANT_ID="${CELASTRINA_IMAGE_NAME}"

# Install logo
install -Dm644 /ctx/celastrina-logo.png /usr/share/pixmaps/celastrina-logo.png

# ── KDE About System ────────────────────────────────────────────────────────

mkdir -p /etc/xdg
cat >/etc/xdg/kcm-about-distrorc <<EOF
[General]
LogoPath=/usr/share/pixmaps/celastrina-logo.png
Name=Celastrina
Website=https://github.com/butterflyskies/celastrina
Variant=${CELASTRINA_VARIANT}
EOF

# ── image-info.json ──────────────────────────────────────────────────────────
# Patch the ublue image metadata used by ublue-motd, fastfetch, etc.

IMAGE_INFO="/usr/share/ublue-os/image-info.json"

# Source os-release for fedora version before we patch it
# shellcheck disable=SC1091
source /usr/lib/os-release

IMAGE_VERSION="${VERSION_ID}.$(date -u +%Y%m%d)"

jq \
	--arg name "$CELASTRINA_IMAGE_NAME" \
	--arg vendor "butterflyskies" \
	--arg ref "ostree-image-signed:docker://ghcr.io/butterflyskies/${CELASTRINA_IMAGE_NAME}" \
	--arg version "$IMAGE_VERSION" \
	--arg pretty "Stable (F${IMAGE_VERSION})" \
	'.
	| ."image-name" = $name
	| ."image-vendor" = $vendor
	| ."image-ref" = $ref
	| .version = $version
	| ."version-pretty" = $pretty
	' "$IMAGE_INFO" > "${IMAGE_INFO}.tmp" && mv "${IMAGE_INFO}.tmp" "$IMAGE_INFO"

# ── MOTD ─────────────────────────────────────────────────────────────────────
# Replace Bazzite's MOTD with Celastrina branding and update the renderer
# to point at the new file.

install -Dm644 /ctx/celastrina-motd.md /usr/share/ublue-os/motd/celastrina.md
rm -f /usr/share/ublue-os/motd/bazzite.md
sed -i 's|/usr/share/ublue-os/motd/bazzite\.md|/usr/share/ublue-os/motd/celastrina.md|g' /usr/libexec/ublue-motd

# ── /usr/lib/os-release ─────────────────────────────────────────────────────
# Patch the base image's os-release in place, preserving fields we don't touch
# (VERSION, VERSION_ID, ID_LIKE, OSTREE_VERSION, SUPPORT_END, etc.)

OS_RELEASE="/usr/lib/os-release"

# Source existing os-release to extract values we need for derived fields
# shellcheck disable=SC1090
source "$OS_RELEASE"

# Extract the parenthesized build version from BOOTLOADER_NAME, e.g. "(F43.20260212)"
BOOT_VERSION="${BOOTLOADER_NAME##*(}"
BOOT_VERSION="${BOOT_VERSION%)}"

# Construct IMAGE_ID: <image-name>-<VERSION_ID>.<YYYYMMDD>
BUILD_DATE=$(date -u +%Y%m%d)
NEW_IMAGE_ID="${CELASTRINA_IMAGE_NAME}-${VERSION_ID}.${BUILD_DATE}"

# Patch fields
sed -i \
	-e 's|^NAME=.*|NAME="Celastrina"|' \
	-e 's|^ID=.*|ID=celastrina|' \
	-e 's|^PRETTY_NAME=.*|PRETTY_NAME="Celastrina"|' \
	-e 's|^DEFAULT_HOSTNAME=.*|DEFAULT_HOSTNAME="celastrina"|' \
	-e 's|^HOME_URL=.*|HOME_URL="https://github.com/butterflyskies/celastrina"|' \
	-e 's|^SUPPORT_URL=.*|SUPPORT_URL="https://github.com/butterflyskies/celastrina"|' \
	-e 's|^BUG_REPORT_URL=.*|BUG_REPORT_URL="https://github.com/butterflyskies/celastrina/issues"|' \
	-e "s|^VARIANT_ID=.*|VARIANT_ID=${CELASTRINA_VARIANT_ID}|" \
	-e "s|^BOOTLOADER_NAME=.*|BOOTLOADER_NAME=\"Celastrina (${BOOT_VERSION})\"|" \
	-e "s|^IMAGE_ID=.*|IMAGE_ID=\"${NEW_IMAGE_ID}\"|" \
	-e 's|^LOGO=.*|LOGO=celastrina-logo|' \
	-e '/^DOCUMENTATION_URL=/d' \
	"$OS_RELEASE"

echo "Configured Celastrina branding (Variant: ${CELASTRINA_VARIANT})"
echo "os-release patched:"
cat "$OS_RELEASE"
