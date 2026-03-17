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
├── docker-compose.yml        # Nextcloud AIO deployment
├── scripts/
│   ├── provision/
│   │   ├── 01-base-setup.sh
│   │   ├── 02-raid-setup.sh
│   │   ├── 03-docker-install.sh
│   │   └── 04-deploy-nextcloud.sh
│   ├── index-media.sh
│   ├── setup-previews.sh
│   └── backup.sh
├── config/
│   └── custom.config.php
└── docs/                     # Full project plan and operational docs
    └── README.md             # Detailed build plan
```

## Getting Started

See [docs/README.md](docs/README.md) for the full project plan, architecture diagrams, hardware requirements, folder structure, permissions model, app stack, backup strategy, and build phase details.
