# Quick-Start Testing Guide

Test the archive setup on your own computer before the server hardware arrives. This runs a throwaway Nextcloud instance locally so you can explore the interface, practice creating groups and folders, test permissions, and get comfortable with the system.

Nothing you do here affects production. When you're done, tear it all down with one command.

## Prerequisites

You need Docker running on your machine. Pick your OS:

**Windows**
1. Install [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
2. During setup, enable WSL 2 backend (recommended)
3. After install, open Docker Desktop and confirm it says "Docker Desktop is running"

**Mac**
1. Install [Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/)
2. Open Docker Desktop and confirm it's running

**Linux**
1. Install Docker Engine: https://docs.docker.com/engine/install/
2. Confirm with `docker --version`

## Step 1 -- Clone the Repo

```bash
git clone https://github.com/YOUR-ORG/steffi-nossen-archive.git
cd steffi-nossen-archive
```

## Step 2 -- Start the Local Test Instance

Run the local-only compose file (no SSL, no domain required):

```bash
docker compose -f docker-compose.local.yml up -d
```

This pulls the Nextcloud AIO image and starts the master container. It may take a few minutes on the first run.

## Step 3 -- Open the AIO Dashboard

Open your browser and go to:

```
https://localhost:8080
```

Your browser will warn about a self-signed certificate. This is expected for local testing -- click through the warning (Advanced > Proceed / Accept Risk).

The AIO dashboard will show you a **passphrase**. Save this -- you need it to log back in to the dashboard.

## Step 4 -- Complete the Setup Wizard

1. In the AIO dashboard, set the domain to `localhost`
2. Skip any optional containers for now (you can enable ClamAV, Talk, etc. later)
3. Click **Start containers**
4. Wait for all containers to start (this takes 2-5 minutes)
5. Once ready, the dashboard shows a link to your Nextcloud instance and the **initial admin password**

## Step 5 -- Log In to Nextcloud

Go to:

```
https://localhost:8443
```

Accept the self-signed certificate warning again. Log in with:
- Username: `admin`
- Password: (the one shown in the AIO dashboard)

You now have a working Nextcloud instance.

## Step 6 -- Test the Permission Model

Walk through the setup described in [PERMISSIONS.md](PERMISSIONS.md):

### Create Groups

1. Click your profile icon (top right) > **Users**
2. In the left sidebar, click **Add group**
3. Create: `admins`, `viewers-private`, `editors-uploads`, `editors-alumni`

### Install Group Folders

1. Click your profile icon > **Apps**
2. Search for "Group folders"
3. Click **Download and enable**

### Create Team Folders

1. Go to **Administration settings** (profile icon > Administration settings)
2. Click **Group folders** in the left sidebar
3. Create each folder: `Public`, `Archive`, `Uploads`, `Restricted`, `Admin`
4. For each folder, add the appropriate groups with the permissions from [PERMISSIONS.md](PERMISSIONS.md)

### Create Test Users

1. Go to **Users**
2. Create a few test accounts:
   - `test-viewer` -- add to `viewers-private`
   - `test-editor` -- add to `editors-uploads`
3. Open a private/incognito browser window
4. Log in as `test-viewer` at `https://localhost:8443`
5. Confirm they can see `Public` and `Archive` but cannot upload
6. Log in as `test-editor`
7. Confirm they can upload to `Uploads/` but cannot write to `Archive/`

## Step 7 -- Test Media Features

### Upload Sample Content

1. Log in as admin
2. Navigate to `Archive/`
3. Create a subfolder like `2024/Spring-Gala/Photos/`
4. Upload a few photos (JPEGs work best for testing)
5. Upload a short video clip if you have one

### Install and Test Memories

1. Go to **Apps** > search "Memories" > **Download and enable**
2. Go to **Administration settings** > **Memories** and review the config
3. Run the indexer from the AIO dashboard or wait for cron
4. Click the **Memories** icon in the top navigation bar
5. Confirm your uploaded photos appear in a timeline view

### Test Preview Generation

1. Go to **Apps** > search "Preview Generator" > **Download and enable**
2. After installation, browse your uploaded photos
3. Thumbnails should render without long delays

## Step 8 -- Test the Backup Script (Optional)

You can test the backup script logic locally, though it won't run the full RAID/USB workflow:

```bash
# Create a fake backup target
mkdir -p /tmp/test-backup

# Review what the script does (read-only)
cat scripts/backup.sh
```

The real backup testing happens on the production server with actual USB drives.

## Step 9 -- Explore Other Apps

Try installing the Day 1 and Day 2 apps from [APPS.md](APPS.md) to see how they work:

- **Files Access Control** -- set up a test rule
- **Files Automated Tagging** -- create a tag and an auto-tagging rule
- **MetaVox** -- add custom metadata fields to a file
- **AutoRename** -- configure a rename pattern and upload a file

Not everything will work perfectly in a local test (e.g., full-text search needs Elasticsearch which is resource-heavy), but you'll get a good feel for the interface and workflow.

## Tear Down

When you're done testing, remove everything:

```bash
# Stop and remove all containers
docker compose -f docker-compose.local.yml down

# Remove all data volumes (starts fresh next time)
docker compose -f docker-compose.local.yml down -v

# Remove AIO's sibling containers (AIO creates these outside compose)
docker stop $(docker ps -q --filter "name=nextcloud-aio-") 2>/dev/null
docker rm $(docker ps -aq --filter "name=nextcloud-aio-") 2>/dev/null

# Remove AIO volumes
docker volume ls --filter "name=nextcloud_aio" -q | xargs -r docker volume rm
```

This deletes all test data. Nothing persists after teardown.

## What This Test Validates

| Area | What you're confirming |
|---|---|
| AIO deployment | Docker pulls the right images, containers start |
| Nextcloud UI | Login, navigation, file browsing all work |
| Group Folders | Team Folders appear for the right groups |
| Permissions | Viewers can't write, editors can only write to Uploads |
| Memories | Photos appear in timeline, video playback works |
| Preview Generator | Thumbnails render without excessive delay |
| App installation | Day 1 and Day 2 apps install and are configurable |

## What This Test Does NOT Validate

| Area | Why it can't be tested locally |
|---|---|
| RAID1 setup | Requires 2 physical HDDs |
| SSL certificates | Requires a real domain and public IP |
| Port forwarding | Requires router access |
| USB backup | Requires physical USB drives |
| Upload speed | Requires the building's internet connection |
| ClamAV performance | Resource-heavy; may be slow on a laptop |

These are tested during the real deployment on the production server.

## Next Steps After Testing

Once you're comfortable with the interface and workflow:

1. Order the hardware ([HARDWARE.md](HARDWARE.md))
2. Confirm the static IP and domain name ([NETWORK.md](NETWORK.md))
3. Get the board's decision on the privacy policy ([PRIVACY.md](PRIVACY.md))
4. When the machine arrives, follow the production deployment starting with `scripts/provision/01-base-setup.sh`
