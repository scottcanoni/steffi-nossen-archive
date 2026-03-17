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

All commands use the `occ` CLI inside the Nextcloud container:

```bash
OCC="docker exec --user www-data nextcloud-aio-nextcloud php occ"
```

### Add a New User

```bash
# Create the user (you will be prompted for a password)
$OCC user:add --display-name "Jane Smith" jsmith

# Add to the appropriate group
$OCC group:adduser viewers-private jsmith
```

After creation:
1. Email them their credentials
2. If they are in an editor or admin group, they will be prompted to set up 2FA on first login
3. They will automatically see all Team Folders assigned to their group(s)

### Add a New Editor

```bash
$OCC user:add --display-name "Carlos Rivera" crivera
$OCC group:adduser editors-uploads crivera
```

Editors can only write to `Uploads/` subfolders. They are required to set up 2FA.

### Add a New Admin

```bash
$OCC user:add --display-name "Sarah Chen" schen
$OCC group:adduser admins schen
```

Keep the admin group very small (2-3 people maximum).

### Disable a User

```bash
$OCC user:disable jsmith
```

This preserves their data but prevents login. Use this instead of deleting users.

### Delete a User

```bash
# Only if you are sure their data is no longer needed
$OCC user:delete jsmith
```

### List All Users and Their Groups

```bash
$OCC user:list
$OCC group:list
$OCC group:listmembers viewers-private
```

### Reset a User's Password

```bash
$OCC user:resetpassword jsmith
```

---

## Monitoring

### Server Health

```bash
# Docker container status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Disk usage
df -h /mnt/archive /mnt/usb-backup

# RAID array health
cat /proc/mdstat

# Drive SMART status
smartctl -a /dev/sda
smartctl -a /dev/sdb
```

### Nextcloud Status

```bash
OCC="docker exec --user www-data nextcloud-aio-nextcloud php occ"

# System status
$OCC status

# Check for warnings
$OCC check

# Storage usage by user
$OCC user:list --info
```

### Log Files

```bash
# Nextcloud application log
docker exec nextcloud-aio-nextcloud cat /var/www/html/data/nextcloud.log | tail -50

# Docker container logs
docker logs nextcloud-aio-nextcloud --tail 50
docker logs nextcloud-aio-database --tail 50
docker logs caddy --tail 50

# Backup log
tail -50 /var/log/nextcloud-backup.log

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

Run this checklist monthly (ideally during the USB backup rotation):

- [ ] All Docker containers are running (`docker ps`)
- [ ] RAID array is healthy (`cat /proc/mdstat`)
- [ ] SMART status is OK on all drives
- [ ] Disk usage is below 80% on data and boot drives
- [ ] Backup log shows recent successful runs
- [ ] USB rotation was performed this month
- [ ] No critical entries in Nextcloud log
- [ ] SSL certificate is valid and not expiring soon
- [ ] All admin accounts still have working 2FA

---

## Upgrades

### Nextcloud AIO Updates

AIO manages its own updates through the dashboard. The master container automatically checks for updates.

1. Open the AIO dashboard at `https://<server-ip>:8080`
2. If an update is available, the dashboard will show it
3. **Before updating**, run a backup:
   ```bash
   sudo /opt/steffi-nossen-archive/scripts/backup.sh
   ```
4. Click **Start update** in the AIO dashboard
5. Wait for all containers to restart
6. Verify the instance is working

### Manual Container Update

If the dashboard is unresponsive:

```bash
cd /opt/steffi-nossen-archive
docker compose pull
docker compose up -d
```

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

Follow Docker's official upgrade instructions. Generally:

```bash
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

### App Updates

Individual Nextcloud apps are updated through the web interface:

1. Go to **Apps** in the top menu
2. Click **Updates** in the sidebar
3. Review and update apps one at a time
4. Check that nothing broke after each update

Or via CLI:

```bash
$OCC app:update --all
```

---

## Common Tasks

### Move Files from Uploads to Archive

This is the core workflow: editors upload to `Uploads/`, admins curate into `Archive/`.

1. Log in as an admin
2. Navigate to the `Uploads/Incoming/` folder
3. Review new content
4. Add metadata via MetaVox (event name, year, photographer, etc.)
5. Move files to the appropriate `Archive/YYYY/Event-Name/` folder
6. If content is public-safe, also copy or move to `Public/`

After moving files, the indexing cron job will update Memories timeline and search index within the hour.

### Create a Public Share Link

1. Navigate to a file or folder in `Public/`
2. Click the share icon
3. Click **Create a new share link**
4. Set password (if enforced), expiration date, and permissions (Read only)
5. Copy the link and distribute

### Create a File Drop (Upload-Only) Link

For collecting photos from event attendees who don't have accounts:

1. Create a folder like `Uploads/Incoming/Spring-Gala-2025-Submissions/`
2. Share it with a public link
3. Set permissions to **File drop (upload only)**
4. Set a password and expiration date (e.g., 2 weeks after the event)
5. Distribute the link to attendees

### Force Re-Index After Large Import

If you bulk-import files directly to `/mnt/archive/` via rsync or USB:

```bash
$OCC files:scan --all
$OCC memories:index
$OCC preview:generate-all
```

### Check Storage Usage

```bash
# Overall disk usage
df -h /mnt/archive

# Top 10 largest folders in the archive
du -h /mnt/archive --max-depth=3 | sort -rh | head -20

# Usage by Nextcloud user
$OCC user:list --info
```

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

### Nextcloud Stuck in Maintenance Mode

```bash
$OCC maintenance:mode --off
```

If the container isn't running:

```bash
docker start nextcloud-aio-nextcloud
$OCC maintenance:mode --off
```

### Slow Performance

1. Check if preview generation is running in the background:
   ```bash
   docker exec nextcloud-aio-nextcloud ps aux | grep preview
   ```
2. Check available memory:
   ```bash
   free -h
   ```
3. Check disk I/O:
   ```bash
   iotop -oa
   ```
4. Increase PHP memory limit if needed (update `.env` and restart)

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

### Large Upload Failures

If users report upload failures on large files:
1. Verify `NEXTCLOUD_UPLOAD_LIMIT` in `.env` (default: 16G)
2. Check available disk space
3. For very large files (>10 GB), recommend using the Nextcloud desktop sync client or WebDAV instead of the web interface
