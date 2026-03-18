#!/usr/bin/env bash
set -euo pipefail

# Install Docker Engine and the Compose plugin on Ubuntu 24.04 LTS.
# Uses Docker's official apt repository.
# Run as root.

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root." >&2
  exit 1
fi

echo "==> Removing any old Docker packages..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
  apt-get remove -y "$pkg" 2>/dev/null || true
done

echo "==> Adding Docker's official GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "==> Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list

echo "==> Installing Docker Engine..."
apt-get update
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

echo "==> Enabling Docker service..."
systemctl enable --now docker

echo "==> Verifying installation..."
docker --version
docker compose version

echo "==> Docker installation complete."
echo "    Next: run 04-deploy-immich.sh to start Immich."
