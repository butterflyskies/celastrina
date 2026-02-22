#!/usr/bin/env bash

set -ouex pipefail

echo "Installing Grafana Alloy and Prometheus Node Exporter"

# 1. Setup Grafana Repo for Alloy
cat <<EOF >/etc/yum.repos.d/grafana.repo
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

# 2. Pre-create alloy service account and home directory.
# The alloy RPM %post runs 'useradd -m' which fails on base images that ship
# a Rust-based useradd (bazzite:stable) that doesn't support -m.
# Creating the user beforehand makes the scriptlet a harmless no-op.
mkdir -p /var/lib/alloy
useradd -r -d /var/lib/alloy -M -s /sbin/nologin alloy
chown alloy:alloy /var/lib/alloy

# 3. Install packages
# alloy is from the Grafana repo
rpm-ostree install alloy

# 4. Clean up repo (updates handled by image builds)
rm /etc/yum.repos.d/grafana.repo

# 5. Handle Persistent Directories
# ublue/ostree logic: /var is stateful. We must ensure the directories
# exist on the live system via tmpfiles.d.
mkdir -p /usr/lib/tmpfiles.d
cat >/usr/lib/tmpfiles.d/98-observability.conf <<EOF
d /var/lib/alloy 0750 alloy alloy - -
d /etc/alloy 0755 root root - -
EOF
