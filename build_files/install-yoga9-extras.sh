#!/bin/bash

set -ouex pipefail

###############################################################################
# Yoga 9 extras — 2-in-1 / touchscreen / power management packages
# Target: Lenovo Yoga 9 2-in-1 14ILL10 (Intel Lunar Lake)
#
# Already in bazzite:stable (no need to install):
#   libwacom, libinput, thermald, iio-sensor-proxy,
#   tuned-ppd (provides ppd-service — conflicts with power-profiles-daemon)
###############################################################################

# Keyboard backlight control
dnf5 install -y brightnessctl

# --- Module blacklists ---

# iwlwifi_mld — Intel BE201 WiFi 7 driver causes kernel panic during init.
# Regular iwlwifi works fine as fallback.
# See: https://github.com/butterflyskies/celastrina/issues/5#2
rm -f /usr/lib/modprobe.d/blacklist-iwlwifi-mld.conf
cat > /usr/lib/modprobe.d/celastrina-yoga9-blacklist.conf <<'MODPROBE'
blacklist iwlwifi_mld
blacklist lenovo_wmi_gamezone
blacklist gcadapter_oc
MODPROBE

# --- Mask irrelevant hardware hooks from bazzite base ---

# fw-fanctrl-suspend is for Framework laptops; fires every suspend cycle
ln -sf /dev/null /usr/lib/systemd/system-sleep/fw-fanctrl-suspend

# ThinkPad battery threshold udev rules fire 12x per boot on nonexistent sysfs
install -m644 /dev/null /usr/lib/udev/rules.d/99-thinkpad-thresholds-udev.rules

# --- Module load ordering ---

# tcp_bbr must be loaded before sysctl sets net.ipv4.tcp_congestion_control
install -d /usr/lib/modules-load.d
echo 'tcp_bbr' > /usr/lib/modules-load.d/celastrina-bbr.conf

# --- Fix tuned-ppd power profile switching ---
# tuned-ppd crashes parsing composite profile strings (space-separated).
# Drop accelerator-performance from the performance mapping — its aggressive
# CPU pinning and scheduler tweaks aren't needed on a Yoga ultrabook.
install -d /etc/tuned
cat > /etc/tuned/ppd.conf <<'PPD'
[main]
default=performance
battery_detection=true
sysfs_acpi_monitor=true
[profiles]
power-saver=powersave-bazzite
balanced=balanced-bazzite
performance=throughput-performance-bazzite
[battery]
balanced=balanced-battery-bazzite
power-saver=powersave-battery-bazzite
PPD

# --- Kernel arguments (bootc kargs.d) ---

# bootc applies kargs.d/*.toml at image install/upgrade time.
# Priority prefix "99-" ensures these run after Bazzite's base entries.

install -d /usr/lib/bootc/kargs.d

# Lunar Lake stability: prevent xe GPU hangs (PSR) and C-state lockups.
# xe.enable_psr=0   — disables Panel Self Refresh on Intel Xe; avoids display/GPU hang
# intel_idle.max_cstate=1 — caps CPU idle to C1; prevents deep-sleep-induced hangs on LNL
install -m644 /dev/stdin /usr/lib/bootc/kargs.d/99-celastrina-yoga9-stability.toml <<'KARGS'
# Lunar Lake (Intel Arc Xe2) stability parameters for Yoga 9 14ILL10.
# See: https://gitlab.freedesktop.org/drm/xe/kernel/-/issues (PSR hangs)
#      https://bugzilla.kernel.org/show_bug.cgi?id=218204 (LNL C-state lockups)

[[add]]
key = "xe.enable_psr"
value = "0"

[[add]]
key = "intel_idle.max_cstate"
value = "1"
KARGS

# Strip NVIDIA kargs shipped by the bazzite base image.
# The yoga9 variant uses bazzite:stable (no NVIDIA), but the base image's
# kargs.d may still propagate these; remove them so they never appear on boot.
install -m644 /dev/stdin /usr/lib/bootc/kargs.d/99-celastrina-yoga9-strip-nvidia.toml <<'KARGS'
# Remove NVIDIA-specific kernel arguments — the Yoga 9 has no discrete GPU.
# Bazzite:stable may still ship these from its common kargs.d layer.

[[delete]]
key = "nvidia-drm.modeset"
value = "1"

[[delete]]
key = "rd.driver.blacklist"
value = "nouveau"

[[delete]]
key = "modprobe.blacklist"
value = "nouveau"

[[delete]]
key = "gpu_sched.sched_policy"
value = "0"
KARGS

# --- SELinux local policy ---
# Suppress known denials from ostree/bootc environment:
#   - bootupd_t running lsblk (user/group resolution, mount info)
#   - systemd-logind inspecting unlabeled /boot/efi
#   - SDDM checking /run/ostree-booted
#   - podman pasta traversing ~/.local
checkmodule -M -m -o /tmp/celastrina-yoga9.mod /ctx/selinux/celastrina-yoga9.te
semodule_package -o /tmp/celastrina-yoga9.pp -m /tmp/celastrina-yoga9.mod
install -D -m644 /tmp/celastrina-yoga9.pp /usr/share/selinux/packages/celastrina-yoga9.pp
semodule -i /tmp/celastrina-yoga9.pp
rm -f /tmp/celastrina-yoga9.{mod,pp}
