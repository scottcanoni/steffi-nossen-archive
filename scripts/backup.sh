#!/usr/bin/env bash
set -euo pipefail

# Backup the Immich archive to a mounted USB drive.
#
# This script:
#   1. Dumps the PostgreSQL database
#   2. Syncs the upload directory to the USB drive
#   3. Syncs the external library to the USB drive
#   4. Verifies the backup
#
# Usage:
#   sudo ./backup.sh                    # Uses default USB mount
#   sudo ./backup.sh /mnt/usb-backup    # Specify USB mount point

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root." >&2
  exit 1
fi

USB_MOUNT="${1:-/mnt/usb-backup}"
UPLOAD_DIR="/mnt/archive/immich-uploads"
EXTERNAL_DIR="/mnt/archive/external"
DB_CONTAINER="immich_postgres"
BACKUP_DIR="$USB_MOUNT/immich-backup"
DB_DUMP_DIR="$BACKUP_DIR/database"
TIMESTAMP="$(date '+%Y-%m-%d_%H%M%S')"
LOG_FILE="/var/log/immich-backup.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "========================================="
log "Immich backup starting"
log "========================================="

if ! mountpoint -q "$USB_MOUNT"; then
  log "ERROR: $USB_MOUNT is not a mounted filesystem."
  log "Mount the USB drive first:"
  log "  mount /dev/sdX1 $USB_MOUNT"
  exit 1
fi

USB_FREE=$(df -BG "$USB_MOUNT" | tail -1 | awk '{print $4}' | tr -d 'G')
log "USB free space: ${USB_FREE}G"

if [[ "$USB_FREE" -lt 10 ]]; then
  log "WARNING: Less than 10 GB free on backup drive."
fi

mkdir -p "$DB_DUMP_DIR"
mkdir -p "$BACKUP_DIR/uploads"
mkdir -p "$BACKUP_DIR/external"

log "==> Dumping PostgreSQL database..."
docker exec "$DB_CONTAINER" \
  pg_dumpall -U postgres \
  | gzip > "$DB_DUMP_DIR/db_${TIMESTAMP}.sql.gz"

log "==> Syncing upload directory ($UPLOAD_DIR -> $BACKUP_DIR/uploads/)..."
if [[ -d "$UPLOAD_DIR" ]]; then
  rsync -aH --delete --info=progress2 \
    "$UPLOAD_DIR/" "$BACKUP_DIR/uploads/"
else
  log "WARNING: Upload directory $UPLOAD_DIR does not exist. Skipping."
fi

log "==> Syncing external library ($EXTERNAL_DIR -> $BACKUP_DIR/external/)..."
if [[ -d "$EXTERNAL_DIR" ]]; then
  rsync -aH --delete --info=progress2 \
    "$EXTERNAL_DIR/" "$BACKUP_DIR/external/"
else
  log "WARNING: External library $EXTERNAL_DIR does not exist. Skipping."
fi

log "==> Cleaning old database dumps (keeping last 5)..."
ls -t "$DB_DUMP_DIR"/db_*.sql.gz 2>/dev/null \
  | tail -n +6 \
  | xargs -r rm -v

log "==> Verifying backup..."
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | awk '{print $1}')
DB_COUNT=$(ls "$DB_DUMP_DIR"/db_*.sql.gz 2>/dev/null | wc -l)
UPLOAD_FILES=$(find "$BACKUP_DIR/uploads" -type f 2>/dev/null | wc -l)
EXTERNAL_FILES=$(find "$BACKUP_DIR/external" -type f 2>/dev/null | wc -l)

log "    Backup directory size: $BACKUP_SIZE"
log "    Database dumps on disk: $DB_COUNT"
log "    Upload files backed up: $UPLOAD_FILES"
log "    External library files backed up: $EXTERNAL_FILES"

log "========================================="
log "Backup complete: $TIMESTAMP"
log "========================================="
log ""
log "If this is a USB rotation swap:"
log "  1. Unmount this drive:  umount $USB_MOUNT"
log "  2. Hand it to the volunteer for offsite storage"
log "  3. Mount the incoming drive and verify it"
