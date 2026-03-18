# Hardware Requirements

## Recommended Configuration

- **CPU**: Modern x86-64, 4+ cores. Video transcoding and ML inference benefit from more cores.
- **RAM**: 16 GB minimum. Immich's machine learning models load into memory for face detection and CLIP search. 32 GB is better if the budget allows.
- **Boot drive**: 120+ GB SSD or NVMe. Ubuntu OS, Docker engine, PostgreSQL database.
- **Data drive**: Large HDD (or 2x identical NAS-grade HDDs in RAID1 if available). Mounted at `/mnt/archive`. All photos, videos, and external libraries live here.
- **Backup drives**: 2x external USB HDDs. Capacity >= data drive. One connected, one offsite.
- **UPS**: Battery backup to protect against corruption from power loss during writes.

## Drive Layout

```
┌─────────────────────────────────────────┐
│  SSD / NVMe (boot)                      │
│  ├── /          Ubuntu 24.04 LTS root   │
│  ├── /var       Docker volumes, images  │
│  └── PostgreSQL data (fast I/O)         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  HDD (single drive or RAID1 pair)       │
│  Mounted at /mnt/archive                │
│                                         │
│  /mnt/archive/immich-uploads/           │
│  /mnt/archive/external/                 │
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

- Photo (high-res JPEG): 5-15 MB
- Photo (RAW): 25-50 MB
- Video (1080p, 1 hour): 5-15 GB
- Video (4K, 1 hour): 20-50 GB

A 4 TB drive (or 4 TB RAID1 pair) is a reasonable starting point unless you already have a large backlog of video.

## GPU Acceleration (Optional)

Immich's machine learning can use a GPU for faster face detection and CLIP inference. This is entirely optional -- CPU processing works fine, it just takes longer for initial import of large libraries. If the machine has an NVIDIA GPU, Immich supports CUDA acceleration.

## UPS

A basic UPS (e.g., APC Back-UPS 600-900VA) is sufficient. The goal is to survive short outages and give the server time for a clean shutdown. Configure the UPS to trigger an automatic shutdown after a sustained power loss using `apcupsd` or `nut`.

## SMART Monitoring

After setup, `smartmontools` monitors drive health. The provisioning scripts install it automatically. Check drive health periodically:

```bash
smartctl -a /dev/sda
smartctl -a /dev/sdb
```

Set up email alerts in the RUNBOOK if a drive starts reporting errors.
