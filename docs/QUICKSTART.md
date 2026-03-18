# Quick-Start Testing Guide

Test the archive on your own computer before the server hardware arrives. This runs a throwaway Immich instance locally so you can explore the interface, upload photos, browse timelines, and test sharing -- all before the real server exists.

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

```bash
docker compose -f docker-compose.local.yml up -d
```

This pulls the Immich images (server, machine learning, PostgreSQL, Redis) and starts everything. The first run takes a few minutes while images download and the ML models initialize.

## Step 3 -- Open Immich

Open your browser and go to:

```
http://localhost:2283
```

No HTTPS warnings, no certificates -- it just works locally.

## Step 4 -- Create the Admin Account

The first account you create becomes the administrator. Fill in:

- Email address (can be anything for testing, e.g., `admin@test.local`)
- Password
- Name

Click **Sign Up**, then log in.

## Step 5 -- Upload Sample Photos

1. Click the **Upload** button (cloud icon in the top right)
2. Select a few photos from your computer
3. Immich will process them -- generating thumbnails, extracting metadata, and running ML models
4. After processing, photos appear in the **Timeline** view

Try uploading:
- A few JPEGs to see timeline and map features
- A short video clip to test video playback and transcoding
- Photos with faces to test face recognition (appears under **People** in the sidebar)

## Step 6 -- Explore Key Features

### Timeline
Click **Timeline** in the sidebar to browse photos chronologically. Photos are grouped by date automatically based on EXIF metadata.

### Search
Click the search bar and try typing a description like "outdoor" or "group photo". Immich uses CLIP-based search to find photos by meaning, not just filename.

### People
After face recognition runs (may take a few minutes), click **People** in the sidebar to see faces grouped automatically. You can name people by clicking on a face cluster.

### Albums
1. Click **Albums** in the sidebar
2. Click **Create Album**
3. Add a name and select some photos
4. Albums are a key organizational tool for the archive

### Map
If your photos have GPS data, click **Map** in the sidebar to see them plotted on a map.

## Step 7 -- Test Sharing

### Shared Albums
1. Create an album
2. Click the share icon on the album
3. If you create a second user account, you can share the album with them

### Shared Links (Public Access)
1. Open an album
2. Click the share icon, then **Create Link**
3. Optionally set a password and expiration date
4. Copy the link -- anyone with it can view the album without logging in

This is how the **Public** role works: share links give read-only access without an account.

### Create a Test Viewer
1. Go to **Administration** (gear icon in the sidebar) > **User Management**
2. Click **Create User**
3. Create a user like `viewer@test.local`
4. Log in as that user in a private/incognito window
5. Confirm they see only what has been shared with them

## Step 8 -- Test External Library (Optional)

External Libraries let Immich watch a folder on your local disk:

1. Go to **Administration** > **External Libraries**
2. Create a new library for a user
3. Set the import path to a folder inside the container (for local testing, you'd need to add a volume mount to the compose file pointing to a local folder)

This is how existing organized folder structures will be imported on the production server without re-uploading.

## Step 9 -- Explore Admin Settings

Go to **Administration** (gear icon) and explore:

- **Machine Learning**: Toggle face detection and CLIP search on/off
- **Video Transcoding**: Configure transcoding settings
- **Storage Template**: Customize how uploaded files are organized on disk
- **User Management**: Create, disable, and manage users
- **Server Settings**: Customize the instance name and theme

## Tear Down

When you're done testing, remove everything:

```bash
# Stop and remove all containers and volumes (clean slate)
docker compose -f docker-compose.local.yml down -v
```

This deletes all test data. Nothing persists after teardown.

## What This Test Validates

- Immich deployment: Docker pulls the right images, containers start
- Web UI: Login, navigation, timeline browsing all work
- Photo processing: Thumbnails generate, metadata is extracted
- Face recognition: People are detected and grouped
- Search: CLIP search returns relevant results
- Albums and sharing: Albums can be created, shared with users and via public links
- Video: Playback and transcoding work

## What This Test Does NOT Validate

- RAID1 setup: Requires 2 physical HDDs
- SSL certificates: Requires a real domain and public IP
- Port forwarding: Requires router access
- USB backup: Requires physical USB drives
- Upload speed: Requires the building's internet connection
- External Libraries at scale: Requires the actual archive folder structure

These are tested during the real deployment on the production server.

## Next Steps After Testing

Once you're comfortable with the interface:

1. Order the hardware ([HARDWARE.md](HARDWARE.md))
2. Confirm the static IP and domain name ([NETWORK.md](NETWORK.md))
3. Get the board's decision on the privacy policy ([PRIVACY.md](PRIVACY.md))
4. When the machine arrives, follow the production deployment starting with `scripts/provision/01-base-setup.sh`
