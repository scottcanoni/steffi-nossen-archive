#!/usr/bin/env bash
set -euo pipefail

# Detect and reassemble an existing mdadm RAID1 array.
#
# Use this instead of 02-raid-setup.sh when moving the data drives
# to a new machine. The RAID array is self-describing -- this script
# finds it, assembles it, and mounts it at /mnt/archive.
#
# Run as root.

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root." >&2
  exit 1
fi

MOUNT_POINT="/mnt/archive"

echo "==> Scanning for existing RAID arrays..."
mdadm --assemble --scan

if [[ ! -e /dev/md0 ]]; then
  echo "ERROR: No RAID array found." >&2
  echo "If the drives are new, use 02-raid-setup.sh instead." >&2
  exit 1
fi

echo "==> RAID array found:"
mdadm --detail /dev/md0
echo ""

echo "==> Array status:"
cat /proc/mdstat
echo ""

echo "==> Saving mdadm configuration..."
mdadm --detail --scan > /etc/mdadm/mdadm.conf
update-initramfs -u

echo "==> Creating mount point $MOUNT_POINT..."
mkdir -p "$MOUNT_POINT"

RAID_UUID=$(blkid -s UUID -o value /dev/md0)

if grep -q "$RAID_UUID" /etc/fstab; then
  echo "    fstab entry already exists."
else
  echo "==> Adding fstab entry..."
  echo "UUID=$RAID_UUID  $MOUNT_POINT  ext4  defaults,noatime  0  2" >> /etc/fstab
fi

echo "==> Mounting..."
mount "$MOUNT_POINT" 2>/dev/null || echo "    Already mounted."

echo ""
echo "==> Recovery complete."
echo "    Mount point: $MOUNT_POINT"
echo "    Data should be intact. Verify with: ls $MOUNT_POINT"
echo ""
echo "    Next: run 03-docker-install.sh, then 04-deploy-immich.sh"
