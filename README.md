# Steffi Nossen Media Archive

A self-hosted media archive for the Steffi Nossen School of Dance, built on Nextcloud AIO running on Ubuntu Server 24.04 LTS.

## Goal

Provide a low-cost, durable, folder-based archive for photos, videos, documents, and organizational records -- accessible to staff, alumni, and the public through role-based permissions, with no recurring cloud fees.

## Architecture at a Glance

- **Server**: Ubuntu Server 24.04 LTS on dedicated hardware (SSD boot + 2x HDD RAID1 for data)
- **Platform**: Nextcloud All-in-One (Docker) with PostgreSQL, Redis, Caddy, and Let's Encrypt
- **Media**: Memories app with Go-VOD for adaptive video streaming and timeline browsing
- **Access**: Static IP, port-forwarded, with role-based permissions (Public / Viewer / Editor / Admin)
- **Backup**: 3-2-1 strategy using two rotating USB drives (zero cloud cost)

## Build Phases

| Phase | What Gets Built |
|-------|-----------------|
| 1 | OS provisioning: Ubuntu hardening, RAID1 setup, Docker install |
| 2 | Nextcloud AIO deployment: docker-compose, config, SSL |
| 3 | Permissions: Team Folders, groups, ACLs, share policies |
| 4 | App stack and performance: Memories, indexing, previews, cron |
| 5 | Backup infrastructure: USB rotation, Borg backup, restore procedures |
| 6 | Operational runbook: user management, upgrades, privacy policy |

## Repo Layout

```
steffi-nossen-archive/
├── README.md                 # This file
├── .env.example              # Template for all config variables
├── docker-compose.yml        # Nextcloud AIO deployment (production)
├── docker-compose.local.yml  # Local testing (no SSL, no domain)
├── scripts/
│   ├── provision/
│   │   ├── 01-base-setup.sh  # Ubuntu baseline, firewall, essentials
│   │   ├── 02-raid-setup.sh  # mdadm RAID1 creation (new drives)
│   │   ├── 02a-raid-recover.sh # Detect existing RAID (machine swap)
│   │   ├── 03-docker-install.sh
│   │   └── 04-deploy-nextcloud.sh
│   ├── index-media.sh        # Memories + preview + search indexing
│   ├── setup-previews.sh     # Preview Generator configuration
│   └── backup.sh             # USB backup + verification
├── config/
│   └── custom.config.php     # PHP performance overrides
└── docs/
    ├── README.md              # Full build plan + architecture diagram
    ├── QUICKSTART.md          # Local testing guide (start here!)
    ├── HARDWARE.md            # Disk layout, RAM, UPS, drive selection
    ├── NETWORK.md             # Static IP, port forwarding, SSL, DNS
    ├── PERMISSIONS.md         # Roles, groups, Team Folders, ACLs
    ├── APPS.md                # App install order, config, cron schedule
    ├── BACKUP.md              # 3-2-1 strategy, USB rotation, restore
    ├── RUNBOOK.md             # User management, monitoring, upgrades
    └── PRIVACY.md             # Minors policy, EXIF stripping, consent
```

## Where to Begin

Don't have the server hardware yet? Start here:

1. **Try it locally**: [docs/QUICKSTART.md](docs/QUICKSTART.md) walks you through running a test instance on your own computer using Docker. You can explore Nextcloud, create groups, test permissions, and install apps -- all before the real server exists.
2. **Get the domain name** (e.g., `archive.steffinossen.org`) and confirm DNS access.
3. **Confirm the static IP** with the ISP at the building where the server will live.
4. **Test upload speed** from that building -- video streaming depends on it.
5. **Order hardware**: See [docs/HARDWARE.md](docs/HARDWARE.md) for what to buy.
6. **Decide the privacy policy**: The board should review [docs/PRIVACY.md](docs/PRIVACY.md) before launch, especially regarding minors.

## Production Deployment

Once the hardware arrives and Ubuntu is installed:

1. **Read the plan**: [docs/README.md](docs/README.md) covers the full architecture, folder structure, permissions model, and build phases.
2. **Provision the server**: Run the scripts in `scripts/provision/` in order (01 through 04).
3. **Set up the network**: [docs/NETWORK.md](docs/NETWORK.md) covers static IP, DNS, and port forwarding.
4. **Configure permissions**: Follow [docs/PERMISSIONS.md](docs/PERMISSIONS.md) to create groups and Team Folders.
5. **Install apps**: Follow [docs/APPS.md](docs/APPS.md) for the phased app installation.
6. **Set up backups**: Follow [docs/BACKUP.md](docs/BACKUP.md) for USB rotation and scheduling.
7. **Operate**: [docs/RUNBOOK.md](docs/RUNBOOK.md) covers day-to-day administration.
