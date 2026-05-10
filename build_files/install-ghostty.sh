#!/usr/bin/env bash

set -ouex pipefail

echo "Installing Ghostty"

# Add COPR repo for ghostty
curl -fsSL "https://copr.fedorainfracloud.org/coprs/scottames/ghostty/repo/fedora-$(rpm -E %fedora)/scottames-ghostty-fedora-$(rpm -E %fedora).repo" \
    -o /etc/yum.repos.d/scottames-ghostty.repo

# Install
rpm-ostree install ghostty

# Remove the repo — updates ship with new images
rm /etc/yum.repos.d/scottames-ghostty.repo
