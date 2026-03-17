#!/usr/bin/env bash
set -euo pipefail

# Ubuntu Server 24.04 LTS baseline provisioning.
# Run as root (or with sudo) on a fresh install.

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root." >&2
  exit 1
fi

echo "==> Updating package index and upgrading installed packages..."
apt-get update
apt-get upgrade -y

echo "==> Installing essential packages..."
apt-get install -y \
  curl \
  wget \
  git \
  htop \
  iotop \
  tmux \
  unattended-upgrades \
  apt-listchanges \
  mdadm \
  smartmontools \
  ufw \
  fail2ban \
  ca-certificates \
  gnupg \
  lsb-release

echo "==> Enabling unattended security updates..."
dpkg-reconfigure -plow unattended-upgrades

echo "==> Configuring firewall (ufw)..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp    # HTTP (redirect to HTTPS)
ufw allow 443/tcp   # HTTPS
ufw allow 8080/tcp  # Nextcloud AIO dashboard
ufw allow 3478/tcp  # STUN (Nextcloud Talk)
ufw allow 3478/udp
ufw --force enable

echo "==> Enabling fail2ban..."
systemctl enable --now fail2ban

echo "==> Setting timezone to America/New_York..."
timedatectl set-timezone America/New_York

echo "==> Enabling NTP time sync..."
timedatectl set-ntp true

echo "==> Base setup complete."
echo "    Next: run 02-raid-setup.sh to configure storage."
