#!/bin/bash

set -ouex pipefail

function install-system() {
	### Install packages — laptop variant (Intel Lunar Lake, no NVIDIA)

	# Hardware-agnostic packages (shared with desktop)
	/ctx/install-ceph.sh
	/ctx/install-hyprland.sh
	/ctx/install-addon-packages.sh
	/ctx/install-openh264-and-firefox.sh
	/ctx/install-1password.sh
	/ctx/install-chrome.sh
	/ctx/install-observability.sh
	/ctx/configure-xdg-portal.sh
	/ctx/configure-signing-policy.sh

	# Laptop-specific: firmware and hardware enablement
	/ctx/install-laptop-firmware.sh
	/ctx/install-laptop-extras.sh
}

set +x
# snapshot users/groups before installs
BEFORE_PW=$(mktemp)
BEFORE_GR=$(mktemp)
getent passwd | sort >"$BEFORE_PW"
getent group | sort >"$BEFORE_GR"

set -x
install-system
set +x

# snapshot after installs
AFTER_PW=$(mktemp)
AFTER_GR=$(mktemp)
getent passwd | sort >"$AFTER_PW"
getent group | sort >"$AFTER_GR"

# output file baked into the image
SYSUSERS_OUT="/usr/lib/sysusers.d/99-local-packages.conf"
mkdir -p "$(dirname "$SYSUSERS_OUT")"
: >"$SYSUSERS_OUT"

# helper: map gid -> group name from AFTER snapshot
# (assumes unique gid→name mapping)
declare -A GID2NAME
while IFS=: read -r gname _ gid _; do
	GID2NAME["$gid"]="$gname"
done <"$AFTER_GR"

# build sets of "before" users/groups for quick membership checks
declare -A BEFORE_USERS BEFORE_GROUPS
while IFS=: read -r uname _ _ _ _ _ _; do BEFORE_USERS["$uname"]=1; done <"$BEFORE_PW"
while IFS=: read -r gname _ _ _; do BEFORE_GROUPS["$gname"]=1; done <"$BEFORE_GR"

# emit sysusers for *new* groups (system-ish only: gid < 1000)
while IFS=: read -r gname _ gid _; do
	[[ -n "${BEFORE_GROUPS[$gname]:-}" ]] && continue
	# only capture system groups; adjust threshold if your site policy differs
	if [[ "$gid" -lt 1000 ]]; then
		printf 'g %s %s\n' "$gname" "$gid" >>"$SYSUSERS_OUT"
	fi
done <"$AFTER_GR"

# emit sysusers for *new* users (system-ish only: uid < 1000 OR nologin/false shells)
while IFS=: read -r uname x uid gid gecos home shell; do
	[[ -n "${BEFORE_USERS[$uname]:-}" ]] && continue

	# heuristics for service accounts
	if [[ "$uid" -lt 1000 || "$shell" == "/sbin/nologin" || "$shell" == "/bin/false" ]]; then
		# ensure primary group exists in sysusers (by name) if it was added
		gname="${GID2NAME[$gid]}"
		# user line: u name uid:group "GECOS" home shell
		# quote GECOS if present; fall back to "-" to be minimal
		[[ -z "$gecos" ]] && gecos="-" || gecos="\"$gecos\""
		[[ -z "$home" ]] && home="-"
		[[ -z "$shell" ]] && shell="-"
		if [[ -n "$gname" ]]; then
			printf 'u %s %s:%s %s %s %s\n' "$uname" "$uid" "$gname" "$gecos" "$home" "$shell" >>"$SYSUSERS_OUT"
		else
			# if we couldn't map gid→name, just pin numeric gid by using a pre-created group
			printf 'u %s %s %s %s %s\n' "$uname" "$uid" "$gecos" "$home" "$shell" >>"$SYSUSERS_OUT"
		fi
	fi
done <"$AFTER_PW"
set -x

# make result readable in the image
chmod 0644 "$SYSUSERS_OUT"

cat "$SYSUSERS_OUT"

# Create tmpfiles rules
cat >/usr/lib/tmpfiles.d/99-local-packages.conf <<EOF
# dhcpcd (present in base)
d /var/lib/dhcpcd 0755 root dhcpcd - -

d /var/lib/pcp 0755 root root - -
d /var/lib/pcp/config 0755 root root - -
d /var/lib/pcp/config/derived 0755 root root - -
d /var/lib/rpm-state 0755 root root - -
EOF

ls -lR /boot
# cleanup
rm -f "$BEFORE_PW" "$BEFORE_GR" "$AFTER_PW" "$AFTER_GR"
