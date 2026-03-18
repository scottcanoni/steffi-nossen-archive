# Backup Strategy

## Overview

The archive follows a **3-2-1 backup strategy** with zero recurring cloud costs:

1. **Live server** -- HDD (or RAID1 mirrored HDDs) for the running archive
2. **Local USB backup** -- A USB drive connected to the server receives scheduled backups
3. **Offsite USB rotation** -- A second USB drive is kept at a volunteer's home and swapped periodically

```
Live Server (HDD / RAID1)
       │
       ▼
USB Drive A (connected, receiving backups)
       │
       ▼ (swap monthly)
USB Drive B (offsite, at volunteer's home)
```

### What RAID1 Does and Does Not Do

If two HDDs are configured as RAID1, the server survives a single drive failure without downtime. RAID1 does **not** protect against:

- Accidental deletion
- Ransomware or malware
- File corruption
- Bad edits
- Theft or fire at the server location

That is why separate backups are mandatory. If using a single HDD (no RAID), backups are even more critical.

## Equipment

- **2x identical external USB HDDs** -- capacity must be at least as large as the data drive
- Label them clearly: **"Backup A"** and **"Backup B"**
- Use the same filesystem (ext4) for reliability

### Formatting a New USB Backup Drive

```bash
# Identify the USB drive (be careful not to wipe the wrong device)
lsblk

# Format as ext4 (replace /dev/sdX with the actual device)
sudo mkfs.ext4 -L backup-a /dev/sdX1

# Create mount point
sudo mkdir -p /mnt/usb-backup

# Mount
sudo mount /dev/sdX1 /mnt/usb-backup
```

## What Gets Backed Up

- **Upload directory** (`/mnt/archive/immich-uploads/`): All photos and videos uploaded through Immich
- **External library** (`/mnt/archive/external/`): The curated folder-based archive
- **PostgreSQL database**: User accounts, albums, sharing settings, face recognition data, metadata, search index

## Scheduled Backups

The on-site USB drive should receive automated backups. Add a cron job:

```bash
# /etc/cron.d/immich-backup
# Run backup every night at 3 AM
0 3 * * * root /opt/steffi-nossen-archive/scripts/backup.sh >> /var/log/immich-backup.log 2>&1
```

### What the Backup Script Does

1. Verifies the USB drive is mounted
2. Dumps the PostgreSQL database to a timestamped, gzipped file
3. Rsyncs the upload directory to the USB drive
4. Rsyncs the external library to the USB drive
5. Cleans up old database dumps (keeps the 5 most recent)
6. Logs backup size and file counts for verification

## USB Rotation Procedure

Perform this swap on a regular schedule (e.g., monthly):

### Step 1 -- Volunteer Arrives with Offsite Drive

The volunteer brings the offsite USB drive (e.g., "Backup B") to the server location.

### Step 2 -- Run Backup to the Incoming Drive

```bash
# Mount the incoming drive
sudo mount /dev/sdX1 /mnt/usb-backup

# Run a full backup
sudo /opt/steffi-nossen-archive/scripts/backup.sh /mnt/usb-backup

# Verify the backup completed successfully (check the log output)
```

### Step 3 -- Unmount and Swap

```bash
# Unmount the freshly backed-up drive
sudo umount /mnt/usb-backup
```

- The freshly backed-up drive stays connected as the new on-site backup
- Hand the previous on-site drive to the volunteer to take home

### Step 4 -- Log the Swap

```bash
echo "$(date '+%Y-%m-%d') Swapped: Backup B is now on-site, Backup A went offsite with [volunteer name]" \
  >> /var/log/backup-rotation.log
```

## Restore Procedures

### Scenario 1: Single Drive Failure (RAID1)

If one HDD in a RAID1 array fails:

```bash
# Check array status
cat /proc/mdstat

# If degraded, identify the failed drive
mdadm --detail /dev/md0

# Replace the physical drive, then add the new one
mdadm --manage /dev/md0 --add /dev/sdX1

# Monitor the rebuild
watch cat /proc/mdstat
```

The server stays operational during the rebuild. No restore needed.

### Scenario 2: Machine Dies, Data Drive Is Fine

If the server hardware fails but the data drive (or RAID1 pair) is intact:

1. Get any replacement machine
2. Install Ubuntu Server 24.04 LTS on a new SSD
3. Clone this repo and run the provisioning scripts:
   ```bash
   sudo ./scripts/provision/01-base-setup.sh
   sudo ./scripts/provision/02a-raid-recover.sh   # for RAID1 arrays
   # or simply mount the single HDD manually
   sudo ./scripts/provision/03-docker-install.sh
   sudo ./scripts/provision/04-deploy-immich.sh
   ```
4. Immich starts up and finds the existing data at `/mnt/archive`

### Scenario 3: Data Drive Fails / Server Loss

Full restore from USB backup:

1. Set up a new server (Ubuntu + Docker) using the provisioning scripts
2. Mount the USB backup drive:
   ```bash
   sudo mount /dev/sdX1 /mnt/usb-backup
   ```
3. Copy the upload directory and external library back:
   ```bash
   sudo rsync -aH /mnt/usb-backup/immich-backup/uploads/ /mnt/archive/immich-uploads/
   sudo rsync -aH /mnt/usb-backup/immich-backup/external/ /mnt/archive/external/
   ```
4. Start the database container only:
   ```bash
   docker compose up -d database
   ```
5. Restore the database:
   ```bash
   # Find the most recent dump
   ls -t /mnt/usb-backup/immich-backup/database/db_*.sql.gz | head -1

   # Restore it
   gunzip -c /mnt/usb-backup/immich-backup/database/db_LATEST.sql.gz \
     | docker exec -i immich_postgres psql -U postgres immich
   ```
6. Start all remaining containers:
   ```bash
   docker compose up -d
   ```
7. Immich will detect the restored data and resume operation

### Scenario 4: Accidental Deletion

Immich has a **Trash** feature:

1. Deleted photos go to trash and are kept for 30 days by default
2. Go to **Trash** in the sidebar to restore deleted items
3. If the trash has been emptied, restore from the most recent USB backup

## Backup Verification Checklist

Run this monthly (ideally during the USB rotation):

- [ ] Backup log shows successful completion (`/var/log/immich-backup.log`)
- [ ] Database dump exists and is recent
- [ ] Upload directory on backup has a reasonable file count
- [ ] Offsite drive was swapped within the last 30 days
- [ ] RAID array is healthy (if applicable): `cat /proc/mdstat`
- [ ] SMART status on all drives is OK: `smartctl -a /dev/sdX`
