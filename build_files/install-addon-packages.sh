#!/bin/bash

set -ouex pipefail

### Add some repos
dnf5 -y copr enable lionheartp/Hyprland 

dnf5 install -y \
  age \
  ansible ansible-lint \
  autossh \
  bcachefs-tools \
  bpftool bpftrace \
  btrbk \
  buildah \
  cfonts \
  cosign \
  direnv \
  evtest \
  fd-find \
  foot \
  fzf \
  gh \
  git-lfs \
  grim \
  helm \
  htop \
  xorg-x11-server-Xwayland qt5-qtwayland qt6-qtwayland \
  iproute-tc iptables-nft nftables \
  jq yq \
  kmscon \
  k9s \
  kubectl \
  kustomize \
  libguestfs-tools \
  mosh \
  neovim \
  netcat nmap \
  perf \
  podman-remote \
  restic \
  ripgrep \
  slurp \
  strace \
  swappy \
  tilt \
  virt-install virt-manager virt-viewer \
  v4l-utils \
  waypipe \
  xpra \
  zoxide \
  zsh zsh-syntax-highlighting

dnf5 -y copr disable lionheartp/Hyprland

if ! rpm -q nerd-fonts >/dev/null 2>&1; then
  dnf5 -y copr enable che/nerd-fonts
  dnf5 -y install nerd-fonts
  dnf5 -y copr disable che/nerd-fonts
fi

# don't want syslinux-extlinux
rpm -q syslinux-extlinux && dnf5 remove -y syslinux-extlinux syslinux || true

# Flatpaks
cat /ctx/flatpak_install >> /usr/share/ublue-os/bazzite/flatpak/install

# Services
# - podman provides support for distroboxes
systemctl enable podman.socket
