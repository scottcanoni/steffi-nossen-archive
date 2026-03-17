# Backup Strategy

## Overview

The archive follows a **3-2-1 backup strategy** with zero recurring cloud costs:

1. **Live server** -- RAID1 mirrored HDDs protect against a single drive failure
2. **Local USB backup** -- A USB drive connected to the server receives scheduled backups
3. **Offsite USB rotation** -- A second USB drive is kept at a volunteer's home and swapped periodically

```
Live Server (RAID1)
       │
       ▼
USB Drive A (connected, receiving backups)
       │
       ▼ (swap monthly)
USB Drive B (offsite, at volunteer's home)
```

### What RAID1 Does and Does Not Do

RAID1 mirrors data across two drives so the server survives a single drive failure without downtime. It does **not** protect against:

- Accidental deletion
- Ransomware or malware
- File corruption
- Bad edits
- Theft or fire at the server location

That is why separate backups are mandatory.

## Equipment

- **2x identical external USB HDDs** -- capacity must be at least as large as the data drives (e.g., 4 TB each if the RAID array is 4 TB)
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

## Scheduled Backups

The on-site USB drive should receive automated backups. Add a cron job:

```bash
# /etc/cron.d/nextcloud-backup
# Run backup every night at 3 AM
0 3 * * * root /opt/steffi-nossen-archive/scripts/backup.sh >> /var/log/nextcloud-backup.log 2>&1
```

### What Gets Backed Up

| Item | Location | Why It Matters |
|---|---|---|
| **User data** | `/mnt/archive/` | All photos, videos, documents -- the entire archive |
| **PostgreSQL database** | Dumped from the `nextcloud-aio-database` container | User accounts, file metadata, shares, app settings |
| **config.php** | Copied from the Nextcloud container | Server identity, encryption keys, trusted domains |

### What the Backup Script Does

1. Puts Nextcloud into maintenance mode (prevents writes during backup)
2. Dumps the PostgreSQL database to a timestamped, gzipped file
3. Rsyncs the entire data directory to the USB drive
4. Copies `config.php` from the Nextcloud container
5. Takes Nextcloud out of maintenance mode
6. Cleans up old database dumps (keeps the 5 most recent)
7. Verifies the backup has files in it

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

### Step 4 -- Mount the New On-Site Drive

```bash
# Mount the drive that was already on-site (now staying)
# It should already be mounted if using automount; verify:
mount | grep usb-backup
```

### Step 5 -- Log the Swap

Record the swap in a simple log so you know which drive is where:

```bash
echo "$(date '+%Y-%m-%d') Swapped: Backup B is now on-site, Backup A went offsite with [volunteer name]" \
  >> /var/log/backup-rotation.log
```

## Nextcloud AIO Built-in Backup (Borg)

Nextcloud AIO includes optional BorgBackup support. This is a complementary backup method that can run alongside the USB backup.

### Enabling Borg Backup in AIO

1. Open the AIO dashboard at `https://<server-ip>:8080`
2. In the backup section, set the **backup directory** to a path on the USB drive (e.g., `/mnt/usb-backup/borg`)
3. Set an **encryption password** and store it securely (in the `Admin/` Team Folder and in a physical safe)
4. AIO will create daily encrypted, deduplicated backups

### Borg Retention Policy

Configured in `.env`:

```
BORG_RETENTION_POLICY=--keep-within=7d --keep-weekly=4 --keep-monthly=6
```

This keeps:
- All backups from the last 7 days
- One per week for 4 weeks
- One per month for 6 months

### Restoring from Borg

AIO can restore a full instance from a Borg backup:

1. Start a fresh AIO instance
2. Open the AIO dashboard
3. Choose **Restore from backup**
4. Point to the Borg repository on the USB drive
5. Enter the encryption password
6. Select the backup snapshot to restore

## Restore Procedures

### Scenario 1: Single Drive Failure (RAID1)

If one HDD in the RAID1 array fails:

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

### Scenario 2: Machine Dies, Data Drives Are Fine

If the server hardware fails but the RAID1 data drives are intact:

1. Get any replacement machine
2. Install Ubuntu Server 24.04 LTS on a new SSD
3. Clone this repo and run the provisioning scripts:
   ```bash
   sudo ./scripts/provision/01-base-setup.sh
   sudo ./scripts/provision/02a-raid-recover.sh   # detects and mounts existing RAID
   sudo ./scripts/provision/03-docker-install.sh
   sudo ./scripts/provision/04-deploy-nextcloud.sh
   ```
4. Complete the AIO setup wizard, restore from Borg backup if available, or run a file scan:
   ```bash
   docker exec --user www-data nextcloud-aio-nextcloud php occ files:scan --all
   docker exec --user www-data nextcloud-aio-nextcloud php occ memories:index
   ```

The RAID1 array is self-describing. The `02a-raid-recover.sh` script finds it automatically regardless of which machine the drives are installed in.

### Scenario 3: Both Drives Fail / Server Loss

Full restore from USB backup:

1. Set up a new server (Ubuntu + Docker + Nextcloud AIO) using the provisioning scripts
2. Mount the USB backup drive
3. Copy the data directory back to `/mnt/archive/`:
   ```bash
   rsync -aH /mnt/usb-backup/nextcloud-backup/data/ /mnt/archive/
   ```
4. Restore the database:
   ```bash
   gunzip -c /mnt/usb-backup/nextcloud-backup/database/db_LATEST.sql.gz \
     | docker exec -i nextcloud-aio-database psql -U oc_nextcloud nextcloud_database
   ```
5. Restore `config.php`:
   ```bash
   docker cp /mnt/usb-backup/nextcloud-backup/config/config.php \
     nextcloud-aio-nextcloud:/var/www/html/config/config.php
   ```
6. Restart containers and run a file scan:
   ```bash
   docker restart nextcloud-aio-nextcloud
   docker exec --user www-data nextcloud-aio-nextcloud php occ files:scan --all
   docker exec --user www-data nextcloud-aio-nextcloud php occ memories:index
   ```

### Scenario 4: Accidental Deletion

If files were accidentally deleted:

1. Check the Nextcloud trash (files are kept for 30 days by default)
2. If not in trash, restore from the most recent USB backup using rsync
3. Run `php occ files:scan --all` after restoring files

## Backup Verification Checklist

Run this monthly (ideally during the USB rotation):

- [ ] Backup log shows successful completion (`/var/log/nextcloud-backup.log`)
- [ ] Database dump exists and is recent (`ls -la /mnt/usb-backup/nextcloud-backup/database/`)
- [ ] Data directory on backup has a reasonable file count
- [ ] Offsite drive was swapped within the last 30 days
- [ ] Borg backup password is still accessible to at least 2 admins
- [ ] RAID array is healthy (`cat /proc/mdstat`)
- [ ] SMART status on all drives is OK (`smartctl -a /dev/sdX`)
