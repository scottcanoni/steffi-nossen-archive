# Hardware Requirements

## Recommended Configuration

| Component | Spec | Notes |
|---|---|---|
| **CPU** | Modern x86-64, 4+ cores | Preview generation and video transcoding benefit from more cores |
| **RAM** | 16 GB minimum | Nextcloud + PostgreSQL + Redis + preview rendering + search indexing |
| **Boot drive** | 120+ GB SSD or NVMe | Ubuntu OS, Docker engine, Nextcloud AIO system volumes |
| **Data drives** | 2x identical NAS-grade HDDs | mdadm RAID1 mirror, mounted at `/mnt/archive` |
| **Backup drives** | 2x external USB HDDs | Capacity >= data drives; one connected, one offsite |
| **UPS** | Battery backup | Protects against corruption from power loss during writes |

## Drive Layout

```
┌─────────────────────────────────────────┐
│  SSD / NVMe (boot)                      │
│  ├── /          Ubuntu 24.04 LTS root   │
│  ├── /var       Docker volumes, images  │
│  └── swap       (if configured)         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  HDD 1 ──┐                             │
│           ├── mdadm RAID1 → /dev/md0    │
│  HDD 2 ──┘    mounted at /mnt/archive  │
│                                         │
│  All Nextcloud user data lives here:    │
│    /mnt/archive/                        │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  USB Drive A (on-site backup)           │
│  USB Drive B (offsite at volunteer)     │
│  Rotated periodically                   │
└─────────────────────────────────────────┘
```

## Filesystem

All volumes use **ext4**. It is stable, well-supported, and easy for any future administrator to work with.

## NAS-Grade HDD Recommendations

Look for drives marketed for NAS or continuous operation:
- Western Digital Red Plus (CMR, not SMR)
- Seagate IronWolf
- Toshiba N300

Avoid desktop drives (WD Blue, Seagate Barracuda) -- they are not rated for 24/7 operation.

## Sizing the Data Drives

Estimate based on archive content:

| Content type | Rough size per item |
|---|---|
| Photo (high-res JPEG) | 5-15 MB |
| Photo (RAW) | 25-50 MB |
| Video (1080p, 1 hour) | 5-15 GB |
| Video (4K, 1 hour) | 20-50 GB |
| Scanned document (PDF) | 1-10 MB |

A 4 TB RAID1 pair gives ~4 TB usable space. Start there unless you already have a large backlog of video.

## UPS

A basic UPS (e.g., APC Back-UPS 600-900VA) is sufficient. The goal is to survive short outages and give the server time for a clean shutdown, not to run for hours. Configure the UPS to trigger an automatic shutdown after a sustained power loss using `apcupsd` or `nut`.

## SMART Monitoring

After setup, `smartmontools` monitors drive health. The provisioning scripts install it automatically. Check drive health periodically:

```bash
smartctl -a /dev/sda
smartctl -a /dev/sdb
```

Set up email alerts in the RUNBOOK if a drive starts reporting errors.
