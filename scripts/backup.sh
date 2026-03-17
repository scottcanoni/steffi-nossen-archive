#!/usr/bin/env bash
set -euo pipefail

# Backup the Nextcloud archive to a mounted USB drive.
#
# This script:
#   1. Puts Nextcloud into maintenance mode
#   2. Dumps the PostgreSQL database
#   3. Syncs the data directory and config to the USB drive
#   4. Takes Nextcloud out of maintenance mode
#   5. Verifies the backup
#
# Usage:
#   sudo ./backup.sh                    # Uses default USB mount
#   sudo ./backup.sh /mnt/usb-backup    # Specify USB mount point

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root." >&2
  exit 1
fi

USB_MOUNT="${1:-/mnt/usb-backup}"
DATA_DIR="/mnt/archive"
BACKUP_DIR="$USB_MOUNT/nextcloud-backup"
DB_DUMP_DIR="$BACKUP_DIR/database"
TIMESTAMP="$(date '+%Y-%m-%d_%H%M%S')"
LOG_FILE="/var/log/nextcloud-backup.log"
OCC="docker exec --user www-data nextcloud-aio-nextcloud php occ"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

cleanup() {
  log "Ensuring maintenance mode is OFF..."
  $OCC maintenance:mode --off 2>/dev/null || true
}
trap cleanup EXIT

log "========================================="
log "Nextcloud backup starting"
log "========================================="

if ! mountpoint -q "$USB_MOUNT"; then
  log "ERROR: $USB_MOUNT is not a mounted filesystem."
  log "Mount the USB drive first:"
  log "  mount /dev/sdX1 $USB_MOUNT"
  exit 1
fi

USB_FREE=$(df -BG "$USB_MOUNT" | tail -1 | awk '{print $4}' | tr -d 'G')
DATA_USED=$(du -sG "$DATA_DIR" 2>/dev/null | awk '{print $1}' | tr -d 'G')
log "USB free space: ${USB_FREE}G, Data directory size: ${DATA_USED}G"

if [[ "$USB_FREE" -lt 10 ]]; then
  log "WARNING: Less than 10 GB free on backup drive."
fi

mkdir -p "$DB_DUMP_DIR"
mkdir -p "$BACKUP_DIR/data"

log "==> Enabling Nextcloud maintenance mode..."
$OCC maintenance:mode --on

log "==> Dumping PostgreSQL database..."
docker exec nextcloud-aio-database \
  pg_dump -U oc_nextcloud nextcloud_database \
  | gzip > "$DB_DUMP_DIR/db_${TIMESTAMP}.sql.gz"

log "==> Syncing data directory ($DATA_DIR -> $BACKUP_DIR/data/)..."
rsync -aH --delete --info=progress2 \
  "$DATA_DIR/" "$BACKUP_DIR/data/"

log "==> Backing up Nextcloud config..."
mkdir -p "$BACKUP_DIR/config"
docker cp nextcloud-aio-nextcloud:/var/www/html/config/config.php \
  "$BACKUP_DIR/config/config.php" 2>/dev/null || \
  log "WARNING: Could not copy config.php from container."

log "==> Disabling maintenance mode..."
$OCC maintenance:mode --off
trap - EXIT

log "==> Cleaning old database dumps (keeping last 5)..."
ls -t "$DB_DUMP_DIR"/db_*.sql.gz 2>/dev/null \
  | tail -n +6 \
  | xargs -r rm -v

log "==> Verifying backup..."
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | awk '{print $1}')
DB_COUNT=$(ls "$DB_DUMP_DIR"/db_*.sql.gz 2>/dev/null | wc -l)
DATA_FILES=$(find "$BACKUP_DIR/data" -type f 2>/dev/null | wc -l)

log "    Backup directory size: $BACKUP_SIZE"
log "    Database dumps on disk: $DB_COUNT"
log "    Data files backed up: $DATA_FILES"

if [[ "$DATA_FILES" -eq 0 ]]; then
  log "ERROR: No data files found in backup. Something went wrong."
  exit 1
fi

log "========================================="
log "Backup complete: $TIMESTAMP"
log "========================================="
log ""
log "If this is a USB rotation swap:"
log "  1. Unmount this drive:  umount $USB_MOUNT"
log "  2. Hand it to the volunteer for offsite storage"
log "  3. Mount the incoming drive and verify it"
