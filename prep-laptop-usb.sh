#!/usr/bin/bash
#
# prep-laptop-usb.sh — Prepare a Fedora CoreOS Live USB for laptop installation
#
# Downloads the latest Fedora CoreOS stable live ISO, verifies it,
# and writes it to the target USB drive.  After booting from this USB,
# run install-laptop.sh to install Celastrina.
#
# Usage:
#   ./prep-laptop-usb.sh [/dev/sdb]
#
# Run from the host (not a distrobox) — requires curl, sudo, dd.
#
set -euo pipefail

USB="${1:-/dev/sdb}"
STREAM_URL="https://builds.coreos.fedoraproject.org/streams/stable.json"
ISO_CACHE="/tmp/fcos-stable.iso"

die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo ":: $*"; }

# ── Fetch latest stable ISO metadata ─────────────────────────────────────────

info "Fetching Fedora CoreOS stable stream metadata..."
meta=$(curl -sf "$STREAM_URL")
ISO_URL=$(echo "$meta" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d['architectures']['x86_64']['artifacts']['metal']['formats']['iso']['disk']['location'])
")
ISO_SHA=$(echo "$meta" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d['architectures']['x86_64']['artifacts']['metal']['formats']['iso']['disk']['sha256'])
")
ISO_VER=$(echo "$ISO_URL" | grep -oP 'builds/\K[^/]+')

info "Latest stable: $ISO_VER"
info "URL: $ISO_URL"

# ── Download (skip if cached and checksum matches) ────────────────────────────

if [[ -f "$ISO_CACHE" ]]; then
	info "Cached ISO found at $ISO_CACHE — verifying checksum..."
	actual=$(sha256sum "$ISO_CACHE" | cut -d' ' -f1)
	if [[ "$actual" == "$ISO_SHA" ]]; then
		info "Checksum OK — skipping download."
	else
		info "Checksum mismatch — re-downloading."
		rm -f "$ISO_CACHE"
	fi
fi

if [[ ! -f "$ISO_CACHE" ]]; then
	info "Downloading Fedora CoreOS $ISO_VER..."
	curl -L --progress-bar -o "$ISO_CACHE" "$ISO_URL"
	info "Verifying checksum..."
	actual=$(sha256sum "$ISO_CACHE" | cut -d' ' -f1)
	[[ "$actual" == "$ISO_SHA" ]] || die "Checksum mismatch after download!"
	info "Checksum OK."
fi

# ── USB safety checks ─────────────────────────────────────────────────────────

[[ -b "$USB" ]] || die "$USB is not a block device"

USB_SIZE_BYTES=$(lsblk -dno SIZE --bytes "$USB" 2>/dev/null || echo 0)
(( USB_SIZE_BYTES > 64 * 1024 * 1024 * 1024 )) && die "$USB is larger than 64 GiB — looks like a system disk, refusing"

if lsblk -no MOUNTPOINTS "$USB" | grep -q .; then
	die "$USB or one of its partitions is mounted — unmount before proceeding"
fi

USB_MODEL=$(lsblk -dno MODEL "$USB" 2>/dev/null | xargs)
USB_SIZE=$(lsblk -dno SIZE "$USB" 2>/dev/null | xargs)

echo ""
echo "┌─────────────────────────────────────────────────────────┐"
echo "│  Celastrina Laptop — USB Prep                           │"
echo "│                                                         │"
printf "│  USB:  %-49s│\n" "$USB ($USB_MODEL, $USB_SIZE)"
printf "│  ISO:  %-49s│\n" "Fedora CoreOS $ISO_VER"
echo "│                                                         │"
echo "│  All data on $USB will be OVERWRITTEN.                  │"
echo "└─────────────────────────────────────────────────────────┘"
echo ""
read -rp "Continue? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || exit 0

# ── Write ISO ─────────────────────────────────────────────────────────────────

info "Writing CoreOS ISO to $USB..."
sudo dd if="$ISO_CACHE" of="$USB" bs=4M status=progress oflag=sync conv=fdatasync
info "Sync complete."

echo ""
echo "┌─────────────────────────────────────────────────────────┐"
echo "│  Done! USB is ready to boot.                            │"
echo "│                                                         │"
echo "│  Boot the laptop from this USB, then run:               │"
echo "│                                                         │"
echo "│    curl -LO https://raw.githubusercontent.com/          │"
echo "│      butterflyskies/celastrina/main/install-laptop.sh   │"
echo "│    sudo bash install-laptop.sh                          │"
echo "│                                                         │"
echo "│  Tang server: http://192.168.0.1:8888                   │"
echo "└─────────────────────────────────────────────────────────┘"
