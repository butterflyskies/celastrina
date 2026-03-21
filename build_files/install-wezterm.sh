#!/usr/bin/env bash

set -ouex pipefail

echo "Installing WezTerm (nightly)"

# Add COPR repo for wezterm-nightly
curl -fsSL "https://copr.fedorainfracloud.org/coprs/wezfurlong/wezterm-nightly/repo/fedora-$(rpm -E %fedora)/wezfurlong-wezterm-nightly-fedora-$(rpm -E %fedora).repo" \
    -o /etc/yum.repos.d/wezfurlong-wezterm-nightly.repo

# Install
rpm-ostree install wezterm

# Remove the repo — updates ship with new images
rm /etc/yum.repos.d/wezfurlong-wezterm-nightly.repo
