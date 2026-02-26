#!/usr/bin/bash
#
# Celastrina Laptop Installer
#
# Deploys celastrina-laptop onto a LUKS2-encrypted btrfs root via
# bootc install to-filesystem.  Run from a Fedora CoreOS Live environment.
#
# Usage:
#   sudo ./install-laptop.sh [/dev/nvme0n1]
#
set -euo pipefail

# ── Constants ────────────────────────────────────────────────────────────────

IMAGE="ghcr.io/butterflyskies/celastrina-laptop:latest"
DISK="${1:-/dev/nvme0n1}"
TARGET="/mnt"

ESP_SIZE="512M"
BOOT_SIZE="1G"

LUKS_NAME="luks-root"
LUKS_MAPPER="/dev/mapper/${LUKS_NAME}"

# ── Helpers ──────────────────────────────────────────────────────────────────

die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo ":: $*"; }

prompt_secret() {
	local label="$1" var="$2" confirm
	while true; do
		read -rsp "${label}: " val; echo
		read -rsp "${label} (confirm): " confirm; echo
		if [[ "$val" == "$confirm" ]]; then
			[[ -n "$val" ]] && break
			echo "Value cannot be empty."
		else
			echo "Entries do not match. Try again."
		fi
	done
	printf -v "$var" '%s' "$val"
}

cleanup() {
	info "Cleaning up..."
	umount -R "$TARGET" 2>/dev/null || true
	cryptsetup luksClose "$LUKS_NAME" 2>/dev/null || true
}

# ── Phase 0: Preflight ──────────────────────────────────────────────────────

[[ "$(id -u)" -eq 0 ]] || die "Must run as root"
[[ -b "$DISK" ]]       || die "$DISK is not a block device"

for cmd in podman cryptsetup sfdisk mkfs.btrfs mkfs.ext4 mkfs.fat blkid udevadm useradd chpasswd; do
	command -v "$cmd" &>/dev/null || die "Required tool not found: $cmd"
done

echo ""
echo "┌──────────────────────────────────────────────┐"
echo "│  Celastrina Laptop Installer                 │"
echo "│                                              │"
echo "│  Image: $IMAGE"
echo "│  Disk:  $DISK"
echo "│                                              │"
echo "│  This will ERASE the entire disk.            │"
echo "└──────────────────────────────────────────────┘"
echo ""
read -rp "Continue? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || exit 0

trap cleanup EXIT

# ── Phase 1: Collect secrets ─────────────────────────────────────────────────

echo ""
info "Disk encryption"
prompt_secret "LUKS passphrase" LUKS_PASSPHRASE

echo ""
info "User account"
read -rp "Username: " USERNAME
[[ -n "$USERNAME" ]] || die "Username cannot be empty"
prompt_secret "Password for ${USERNAME}" USER_PASSWORD

echo ""
info "Tang auto-unlock (optional)"
read -rp "Tang server URL [leave blank to skip, e.g. http://192.168.0.1:8888]: " TANG_URL || true

if [[ -n "${TANG_URL:-}" ]]; then
	info "Validating Tang server at ${TANG_URL}..."
	if ! curl -sf --max-time 5 "${TANG_URL}/adv" >/dev/null; then
		echo ""
		echo "ERROR: Tang server unreachable at ${TANG_URL}/adv"
		echo "       Verify the URL and that the server is up before proceeding."
		echo "       (Leave URL blank to install without Tang auto-unlock.)"
		echo ""
		read -rp "Continue anyway without Tang? [y/N] " skip_tang
		if [[ "$skip_tang" =~ ^[Yy]$ ]]; then
			TANG_URL=""
		else
			exit 1
		fi
	else
		info "Tang server reachable — will enroll after LUKS setup."
	fi
fi

# ── Phase 2: Partition ───────────────────────────────────────────────────────

info "Partitioning ${DISK}..."
sfdisk --wipe always "$DISK" <<EOF
label: gpt
size=${ESP_SIZE},  type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, name="EFI-SYSTEM"
size=${BOOT_SIZE}, name="boot"
                   name="root"
EOF
udevadm settle

ESP="${DISK}p1"
BOOT="${DISK}p2"
ROOT_PART="${DISK}p3"

# ── Phase 3: LUKS + filesystems ─────────────────────────────────────────────

info "Formatting LUKS2 on ${ROOT_PART}..."
echo -n "$LUKS_PASSPHRASE" | cryptsetup luksFormat --type luks2 --batch-mode "$ROOT_PART" -

info "Opening LUKS volume..."
echo -n "$LUKS_PASSPHRASE" | cryptsetup luksOpen "$ROOT_PART" "$LUKS_NAME" -

LUKS_UUID=$(cryptsetup luksUUID "$ROOT_PART")
info "LUKS UUID: ${LUKS_UUID}"

# ── Phase 3.5: Clevis Tang enrollment ───────────────────────────────────────

if [[ -n "${TANG_URL:-}" ]]; then
	info "Enrolling LUKS volume with Clevis Tang ($TANG_URL)..."
	if command -v clevis &>/dev/null; then
		if echo -n "$LUKS_PASSPHRASE" | clevis luks bind -f -k - -d "$ROOT_PART" tang "{\"url\":\"$TANG_URL\"}"; then
			info "Tang enrollment successful — disk will auto-unlock via $TANG_URL"
		else
			echo "WARNING: Tang enrollment failed. Enroll manually after first boot:"
			echo "  sudo clevis luks bind -f -d $ROOT_PART tang '{\"url\":\"$TANG_URL\"}'"
		fi
	else
		echo "WARNING: clevis not found in live environment. Enroll manually after first boot:"
		echo "  sudo clevis luks bind -f -d $ROOT_PART tang '{\"url\":\"$TANG_URL\"}'"
	fi
fi

info "Creating filesystems..."
mkfs.btrfs -f -L root "$LUKS_MAPPER"
mkfs.ext4 -F -L boot "$BOOT"
mkfs.fat -F 32 -n EFI "$ESP"

# ── Phase 4: Mount ───────────────────────────────────────────────────────────

info "Mounting target at ${TARGET}..."
mount "$LUKS_MAPPER" "$TARGET"
mkdir -p "${TARGET}/boot"
mount "$BOOT" "${TARGET}/boot"
mkdir -p "${TARGET}/boot/efi"
mount "$ESP" "${TARGET}/boot/efi"

# ── Phase 5: Deploy ─────────────────────────────────────────────────────────

BOOT_UUID=$(blkid -s UUID -o value "$BOOT")
info "Deploying ${IMAGE}..."
info "  root-mount-spec: ${LUKS_MAPPER}"
info "  boot-mount-spec: UUID=${BOOT_UUID}"
info "  rd.luks.uuid:    ${LUKS_UUID}"

podman run --rm --privileged --pid=host \
	--security-opt label=type:unconfined_t \
	-v /var/lib/containers:/var/lib/containers \
	-v /dev:/dev \
	-v "${TARGET}":/target \
	"$IMAGE" \
	bootc install to-filesystem \
	--root-mount-spec "$LUKS_MAPPER" \
	--boot-mount-spec "UUID=${BOOT_UUID}" \
	--karg "rd.luks.uuid=${LUKS_UUID}" \
	--karg "rd.luks.options=discard" \
	--skip-fetch-check \
	/target

# ── Phase 6: User account ───────────────────────────────────────────────────

info "Creating user account: ${USERNAME}"

# Find the ostree deployment root (there should be exactly one after fresh install)
DEPLOY_ROOT=$(find "${TARGET}/ostree/deploy" -maxdepth 3 -mindepth 3 -type d | head -1)
[[ -d "$DEPLOY_ROOT" ]] || die "Could not locate ostree deployment root"
info "Deployment root: ${DEPLOY_ROOT}"

# Build supplementary groups list — only include groups that exist in the deployment
sup_groups="wheel"
for g in input plugdev; do
	if grep -q "^${g}:" "${DEPLOY_ROOT}/etc/group" 2>/dev/null; then
		sup_groups="${sup_groups},${g}"
	fi
done

useradd --root "$DEPLOY_ROOT" -m -G "$sup_groups" -s /bin/bash "$USERNAME"
echo "${USERNAME}:${USER_PASSWORD}" | chpasswd --root "$DEPLOY_ROOT"
info "User ${USERNAME} created (groups: ${sup_groups})"

# ── Phase 7: Done ───────────────────────────────────────────────────────────

trap - EXIT
info "Unmounting..."
umount -R "$TARGET"
cryptsetup luksClose "$LUKS_NAME"

echo ""
echo "┌──────────────────────────────────────────────┐"
echo "│  Installation complete!                      │"
echo "│                                              │"
echo "│  Remove the USB drive and reboot.            │"
echo "│  You will be prompted for your LUKS          │"
echo "│  passphrase during boot.                     │"
echo "└──────────────────────────────────────────────┘"
