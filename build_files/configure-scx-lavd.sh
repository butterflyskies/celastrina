#!/bin/bash
set -ouex pipefail

# Enable scx_lavd as the default sched_ext scheduler.
# Runs as a simple systemd service — no D-Bus loader overhead.
# scx-scheds package is provided by the Bazzite base image.

mkdir -p /usr/lib/systemd/system
cat > /usr/lib/systemd/system/scx_lavd.service << 'UNIT'
[Unit]
Description=scx_lavd scheduler

[Service]
Type=simple
ExecStart=/usr/bin/scx_lavd
KillSignal=SIGINT
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

systemctl enable scx_lavd.service
