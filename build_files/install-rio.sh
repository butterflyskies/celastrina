#!/usr/bin/env bash

set -ouex pipefail

echo "Installing Rio terminal"

# Binary (built in rio-builder stage, mounted at /rio)
install -Dm755 /rio/target/release/rio /usr/bin/rio

# Desktop entry
install -Dm644 /rio/misc/rio.desktop /usr/share/applications/rio.desktop

# Icon
install -Dm644 /rio/misc/logo.svg /usr/share/icons/hicolor/scalable/apps/rio.svg

# Terminfo
tic -xe xterm-rio,rio /rio/misc/rio.terminfo
