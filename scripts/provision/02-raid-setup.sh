#!/usr/bin/env bash
set -euo pipefail

# Create an mdadm RAID1 (mirror) from two HDDs and mount at /mnt/archive.
# Run as root. Assumes the OS is installed on a separate SSD/NVMe.
#
# IMPORTANT: This script will DESTROY all data on the target drives.
# Verify the correct device names before running.

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root." >&2
  exit 1
fi

DRIVE1="${1:-}"
DRIVE2="${2:-}"
MOUNT_POINT="/mnt/archive"

if [[ -z "$DRIVE1" || -z "$DRIVE2" ]]; then
  echo "Usage: $0 /dev/sdX /dev/sdY"
  echo ""
  echo "Available block devices:"
  lsblk -d -o NAME,SIZE,MODEL,TYPE | grep disk
  exit 1
fi

if [[ "$DRIVE1" == "$DRIVE2" ]]; then
  echo "ERROR: Both drives are the same device." >&2
  exit 1
fi

echo ""
echo "WARNING: This will ERASE all data on:"
echo "  $DRIVE1"
echo "  $DRIVE2"
echo ""
read -rp "Type YES to continue: " confirm
if [[ "$confirm" != "YES" ]]; then
  echo "Aborted."
  exit 1
fi

echo "==> Wiping partition tables..."
wipefs -a "$DRIVE1"
wipefs -a "$DRIVE2"

echo "==> Creating partitions..."
parted -s "$DRIVE1" mklabel gpt mkpart primary 0% 100%
parted -s "$DRIVE2" mklabel gpt mkpart primary 0% 100%

PART1="${DRIVE1}1"
PART2="${DRIVE2}1"

echo "==> Waiting for partition devices..."
sleep 2
udevadm settle

echo "==> Creating RAID1 array /dev/md0..."
mdadm --create /dev/md0 \
  --level=1 \
  --raid-devices=2 \
  "$PART1" "$PART2"

echo "==> Saving mdadm configuration..."
mdadm --detail --scan >> /etc/mdadm/mdadm.conf
update-initramfs -u

echo "==> Formatting /dev/md0 as ext4..."
mkfs.ext4 -L archive /dev/md0

echo "==> Creating mount point $MOUNT_POINT..."
mkdir -p "$MOUNT_POINT"

echo "==> Adding fstab entry..."
RAID_UUID=$(blkid -s UUID -o value /dev/md0)
echo "UUID=$RAID_UUID  $MOUNT_POINT  ext4  defaults,noatime  0  2" >> /etc/fstab

echo "==> Mounting..."
mount "$MOUNT_POINT"

echo "==> Setting permissions..."
chown root:root "$MOUNT_POINT"
chmod 755 "$MOUNT_POINT"

echo "==> RAID1 setup complete."
echo "    Mount point: $MOUNT_POINT"
echo "    Array status:"
cat /proc/mdstat
echo ""
echo "    Next: run 03-docker-install.sh to install Docker."
