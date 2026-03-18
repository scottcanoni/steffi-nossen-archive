# Steffi Nossen Media Archive

A self-hosted photo and video archive for the Steffi Nossen School of Dance, built on [Immich](https://immich.app) running on Ubuntu Server 24.04 LTS.

## Goal

Provide a low-cost, durable archive for photos and videos - accessible to staff, alumni, parents, students and the public through role-based granted access, with no recurring cloud fees, as minimal maintenance as possible and portable to a new server easily.

## Architecture at a Glance

- **Server**: Ubuntu Server 24.04 LTS on dedicated hardware (SSD boot + HDD for data)
- **Platform**: Immich (Docker) with PostgreSQL, Redis, and machine learning for smart search
- **Media**: Timeline browsing, albums, face recognition, CLIP-based search, video transcoding
- **Access**: Static IP, HTTPS via Caddy + Let's Encrypt, role-based access (Public / Viewer / Editor / Admin)
- **Backup**: 3-2-1 strategy using two rotating USB drives (zero cloud cost)

## Build Phases

- **Phase 1**: OS provisioning -- Ubuntu hardening, storage setup, Docker install
- **Phase 2**: Immich deployment -- docker-compose, .env, SSL via Caddy
- **Phase 3**: Permissions -- users, shared albums, external libraries
- **Phase 4**: Backup infrastructure -- USB rotation, database dumps, restore procedures
- **Phase 5**: Operational runbook -- user management, upgrades, privacy policy

## Repo Layout

```
steffi-nossen-archive/
├── README.md                     # This file
├── .env.example                  # Template for all config variables
├── docker-compose.yml            # Immich production deployment (with Caddy SSL)
├── docker-compose.local.yml      # Local testing (no SSL, no domain)
├── docker-compose.immich-test.yml # Quick throwaway test instance
├── scripts/
│   ├── provision/
│   │   ├── 01-base-setup.sh      # Ubuntu baseline, firewall, essentials
│   │   ├── 02-raid-setup.sh      # mdadm RAID1 creation (new drives)
│   │   ├── 02a-raid-recover.sh   # Detect existing RAID (machine swap)
│   │   ├── 03-docker-install.sh  # Docker engine + compose plugin
│   │   └── 04-deploy-immich.sh   # Pull and start Immich containers
│   └── backup.sh                 # USB backup (database + files)
└── docs/
    ├── README.md                 # Full build plan + architecture diagram
    ├── QUICKSTART.md             # Local testing guide (start here!)
    ├── HARDWARE.md               # Disk layout, RAM, UPS requirements
    ├── NETWORK.md                # Static IP, port forwarding, SSL
    ├── PERMISSIONS.md            # Roles, shared albums, external libraries
    ├── BACKUP.md                 # 3-2-1 strategy, USB rotation, restore
    ├── RUNBOOK.md                # Day-to-day ops: users, upgrades, monitoring
    └── PRIVACY.md                # Minors policy, metadata, consent
```

## Where to Begin

Don't have the server hardware yet? Start here:

1. **Try it locally**: [docs/QUICKSTART.md](docs/QUICKSTART.md) walks you through running Immich on your own computer using Docker. You can explore the UI, upload photos, test albums and sharing -- all before the real server exists.
2. **Get the domain name** (e.g., `archive.steffinossen.org`) and confirm DNS access.
3. **Confirm the static IP** with the ISP at the building where the server will live.
4. **Test upload speed** from that building -- video streaming depends on it.
5. **Order hardware**: See [docs/HARDWARE.md](docs/HARDWARE.md) for what to buy.
6. **Decide the privacy policy**: The board should review [docs/PRIVACY.md](docs/PRIVACY.md) before launch, especially regarding minors.

## Production Deployment

Once the hardware arrives and Ubuntu is installed:

1. **Read the plan**: [docs/README.md](docs/README.md) covers the full architecture, permissions model, and build phases.
2. **Provision the server**: Run the scripts in `scripts/provision/` in order (01 through 04).
3. **Set up the network**: [docs/NETWORK.md](docs/NETWORK.md) covers static IP, DNS, and port forwarding.
4. **Configure access**: Follow [docs/PERMISSIONS.md](docs/PERMISSIONS.md) to create users and shared albums.
5. **Set up backups**: Follow [docs/BACKUP.md](docs/BACKUP.md) for USB rotation and scheduling.
6. **Operate**: [docs/RUNBOOK.md](docs/RUNBOOK.md) covers day-to-day administration.
