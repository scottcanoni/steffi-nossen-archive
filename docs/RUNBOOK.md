# Operational Runbook

Day-to-day administration procedures for the Steffi Nossen Media Archive.

## Table of Contents

- [User Management](#user-management)
- [Monitoring](#monitoring)
- [Upgrades](#upgrades)
- [Common Tasks](#common-tasks)
- [Troubleshooting](#troubleshooting)

---

## User Management

### Add a New User

1. Log in as admin
2. Go to **Administration** (gear icon) > **User Management**
3. Click **Create User**
4. Fill in name, email, and password
5. The user can log in and start uploading immediately

Or share specific albums with them if they should only have viewing access.

### Disable a User

1. Go to **Administration** > **User Management**
2. Find the user
3. Click the options menu and select **Disable**

Disabled users cannot log in, but their data is preserved.

### Delete a User

1. Go to **Administration** > **User Management**
2. Find the user
3. Click the options menu and select **Delete**

Use disable instead of delete when possible -- deleting removes their uploaded content.

### Reset a User's Password

1. Go to **Administration** > **User Management**
2. Find the user
3. Click the options menu and select **Reset Password**
4. Communicate the new password to the user

---

## Monitoring

### Server Health

```bash
# Docker container status
docker ps --format "table {{.Names}}\t{{.Status}}"

# Disk usage
df -h /mnt/archive /mnt/usb-backup

# RAID array health (if applicable)
cat /proc/mdstat

# Drive SMART status
smartctl -a /dev/sda
smartctl -a /dev/sdb
```

### Immich Status

Open the Immich web interface and go to **Administration** > **Server Info** to see:
- Total photos and videos
- Storage usage
- Active users

### Log Files

```bash
# Immich server logs
docker logs immich_server --tail 50

# Machine learning logs
docker logs immich_machine_learning --tail 50

# Database logs
docker logs immich_postgres --tail 50

# Caddy (SSL proxy) logs
docker logs caddy --tail 50

# Backup log
tail -50 /var/log/immich-backup.log

# System log
journalctl -u docker --since "1 hour ago"
```

### SMART Drive Monitoring Alerts

Configure `smartd` to email on drive errors:

```bash
# /etc/smartd.conf
/dev/sda -a -o on -S on -s (S/../.././02|L/../../6/03) -m admin@steffinossen.org
/dev/sdb -a -o on -S on -s (S/../.././02|L/../../6/03) -m admin@steffinossen.org
```

Restart the service: `systemctl restart smartd`

### Monthly Health Check

- [ ] All Docker containers are running (`docker ps`)
- [ ] RAID array is healthy (if applicable)
- [ ] SMART status is OK on all drives
- [ ] Disk usage is below 80% on data and boot drives
- [ ] Backup log shows recent successful runs
- [ ] USB rotation was performed this month
- [ ] SSL certificate is valid and not expiring soon
- [ ] Admin account is accessible

---

## Upgrades

### Immich Updates

Immich releases are tagged container images. To update:

1. **Backup first**:
   ```bash
   sudo /opt/steffi-nossen-archive/scripts/backup.sh
   ```

2. **Pull new images and restart**:
   ```bash
   cd /opt/steffi-nossen-archive
   docker compose pull
   docker compose up -d
   ```

3. **Verify the instance is working**: Open the web UI and confirm photos load and search works.

To pin a specific version, set `IMMICH_VERSION=v1.x.x` in `.env` instead of `release`.

### Ubuntu System Updates

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

Reboot if a kernel update was installed:

```bash
sudo reboot
```

### Docker Engine Updates

```bash
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

---

## Common Tasks

### Import Existing Photos from Disk

If you have a folder of photos on a USB drive or network share:

1. Copy them to the external library path:
   ```bash
   sudo rsync -aH /mnt/usb-import/photos/ /mnt/archive/external/2024/Event-Name/
   ```

2. Trigger a library rescan in Immich:
   - Go to **Administration** > **External Libraries**
   - Click **Scan** on the relevant library

3. Photos appear in the timeline and become searchable

### Create a Public Shared Link

1. Open an album (or select individual photos)
2. Click the share icon
3. Click **Create Link**
4. Set password and expiration if desired
5. Copy the link and distribute

### Bulk Download from Immich

Admin users can download albums or selections as ZIP files through the web interface:

1. Select photos (or open an album)
2. Click the download icon
3. A ZIP file is generated and downloaded

### Check Storage Usage

```bash
# Overall disk usage
df -h /mnt/archive

# Top largest directories in the archive
du -h /mnt/archive --max-depth=3 | sort -rh | head -20

# Immich uploads specifically
du -sh /mnt/archive/immich-uploads/

# External library
du -sh /mnt/archive/external/
```

### Rescan External Library

If files were added directly to the external library folder:

```bash
# Or through the admin UI:
# Administration > External Libraries > Scan
```

Immich will detect new files and process them (generate thumbnails, extract metadata, run ML).

---

## Troubleshooting

### Container Won't Start

```bash
# Check what failed
docker ps -a --filter "status=exited"
docker logs <container-name> --tail 100

# Restart all containers
cd /opt/steffi-nossen-archive
docker compose down
docker compose up -d
```

### Database Connection Errors

If Immich shows database errors:

```bash
# Check if PostgreSQL is healthy
docker exec immich_postgres pg_isready

# Check PostgreSQL logs
docker logs immich_postgres --tail 50

# Restart just the database
docker compose restart database
```

### Slow Performance

1. Check if ML processing is running (initial import processes all photos):
   ```bash
   docker logs immich_machine_learning --tail 20
   ```
2. Check available memory:
   ```bash
   free -h
   ```
3. Check disk I/O:
   ```bash
   iotop -oa
   ```
4. ML processing is CPU-intensive during initial import -- it will settle down once all photos are processed

### SSL Certificate Problems

Caddy handles SSL automatically. If certificates fail to renew:

1. Verify port 80 is forwarded and reachable from the internet
2. Verify the domain DNS still points to your IP
3. Check Caddy logs:
   ```bash
   docker logs caddy --tail 50
   ```
4. Force a certificate refresh by restarting Caddy:
   ```bash
   docker restart caddy
   ```

### RAID Degraded

```bash
cat /proc/mdstat
mdadm --detail /dev/md0
```

If one drive has failed:
1. Order a replacement drive (same model/size)
2. The server continues operating on the surviving drive
3. See [BACKUP.md](BACKUP.md) Scenario 1 for the replacement procedure

### Photos Not Appearing After Upload

1. Check that the Immich server container is running
2. Check server logs for processing errors:
   ```bash
   docker logs immich_server --tail 50
   ```
3. For external library files, ensure a library scan has been triggered
4. Large uploads may take time to process -- check the **Jobs** page in Administration
