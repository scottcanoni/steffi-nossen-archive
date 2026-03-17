# Nextcloud App Stack

Install apps in the order listed. Each phase builds on the previous one. Do not rush to install everything at once -- get each layer working before adding the next.

## Day 1 -- Foundation

These apps establish the core permission model and security baseline. Install them immediately after the first Nextcloud login.

### 1. Group Folders (Team Folders)

**What it does**: Creates admin-managed shared folders visible to specific groups. This is the structural backbone of the entire archive.

**Install**:
```bash
OCC="docker exec --user www-data nextcloud-aio-nextcloud php occ"
$OCC app:install groupfolders
```

**Configure**: See [PERMISSIONS.md](PERMISSIONS.md) for the full folder and group setup.

---

### 2. Files Access Control

**What it does**: Enforces rules that deny create, modify, delete, download, or sync operations based on conditions like user group, file location, or tags.

**Install**:
```bash
$OCC app:install files_accesscontrol
```

**Configure**: Go to **Administration settings** > **Flow** and add the rules documented in [PERMISSIONS.md](PERMISSIONS.md).

---

### 3. Files Automated Tagging

**What it does**: Automatically assigns collaborative tags to files based on rules (e.g., tag everything in `Uploads/` as `incoming`).

**Install**:
```bash
$OCC app:install files_automatedtagging
```

**Configure**: Create collaborative tags first, then set up tagging rules. See [PERMISSIONS.md](PERMISSIONS.md) for the recommended tag list.

---

### 4. Antivirus for Files (ClamAV)

**What it does**: Scans uploaded files for malware before they are written to storage.

Nextcloud AIO includes ClamAV as an optional container. Enable it in the AIO dashboard rather than installing a separate app.

**Enable**:
1. Open the AIO dashboard at `https://<server-ip>:8080`
2. Check the **ClamAV** option
3. Click **Start containers** (or restart if already running)

The Nextcloud Antivirus app is auto-configured when ClamAV is enabled through AIO.

---

### 5. Two-Factor TOTP Provider

**What it does**: Adds TOTP-based two-factor authentication (works with apps like Google Authenticator, Authy, or any TOTP app).

**Install**:
```bash
$OCC app:install twofactor_totp
```

**Configure**:
1. Go to **Administration settings** > **Security**
2. Enable **Enforce two-factor authentication**
3. Add groups: `admins`, `editors-uploads`, `editors-alumni`

---

### 6. Public Share Settings

These are built-in Nextcloud settings, not a separate app.

**Configure** in **Administration settings** > **Sharing**:
- Set default expiration date for public links (e.g., 90 days)
- Enforce password protection for public links
- Disable public upload by default
- Disable resharing

---

## Day 2 -- Archive Quality-of-Life

Install these once the foundation is solid and users can log in, browse, and upload correctly.

### 7. Memories

**What it does**: High-performance photo and video management with timeline browsing, albums, metadata editing, and adaptive video streaming via Go-VOD.

**Install**:
```bash
$OCC app:install memories
```

**Post-install**:
```bash
# Run the initial media index (this may take a while on a large archive)
$OCC memories:index

# Verify Go-VOD is working for video transcoding
$OCC memories:video-setup
```

**Configure**:
- Go to **Administration settings** > **Memories**
- Enable **Go-VOD** for HLS adaptive streaming
- Point it to the correct ffmpeg/ffprobe paths (AIO includes these)
- If hardware acceleration is available (`NEXTCLOUD_ENABLE_DRI_DEVICE=true` in `.env`), enable it here

Set up a cron job for ongoing indexing -- see **Cron Schedule** below.

---

### 8. Preview Generator

**What it does**: Pre-renders thumbnails so users don't wait for on-the-fly generation. Critical for a photo-heavy archive.

Nextcloud AIO can enable the Imaginary container for faster preview generation. Enable it in the AIO dashboard.

**Install**:
```bash
$OCC app:install previewgenerator
```

**Post-install**:
```bash
# Generate previews for all existing files (long-running on first pass)
$OCC preview:generate-all
```

Use the `setup-previews.sh` script to configure preview sizes. Set up a cron job for ongoing generation -- see **Cron Schedule** below.

---

### 9. Full Text Search

**What it does**: Indexes the content of PDFs, Word documents, and other text-based files for search.

Nextcloud AIO includes an Elasticsearch container as an optional component. Enable it in the AIO dashboard.

**Enable**:
1. Open the AIO dashboard at `https://<server-ip>:8080`
2. Check the **Fulltextsearch** option
3. Click **Start containers**

**Post-install**:
```bash
# Run the initial index
$OCC fulltextsearch:index
```

---

### 10. MetaVox (Custom Metadata)

**What it does**: Adds configurable metadata fields to files. Useful for archival information like event name, year, photographer, and rights status.

**Install**:
```bash
$OCC app:install metavox
```

**Configure**: Define custom metadata fields in **Administration settings** > **MetaVox**:

| Field | Type | Purpose |
|---|---|---|
| Event Name | Text | Name of the performance, gala, or event |
| Year | Number | Year the content was created |
| Photographer | Text | Who took the photo/video |
| Performer(s) | Text | Featured performers |
| Rights Cleared | Checkbox | Whether publication rights have been obtained |
| Public Safe | Checkbox | Whether content can go in the Public folder |
| Notes | Text (long) | Free-form notes for archivists |

---

### 11. AutoRename

**What it does**: Renames files automatically on upload based on rules, using EXIF data, dates, and custom patterns.

**Install**:
```bash
$OCC app:install auto_rename
```

**Configure**: Set up rename rules to standardize messy uploads. For example:

- Pattern: `{date:yyyy-MM-dd}_{original}`
- Result: `2024-05-18_IMG_8821.jpg`

Configure in **Administration settings** > **AutoRename**.

---

## Later -- If Needed

These apps are not required for launch but may become valuable as the organization grows.

| App | Purpose | When to Add |
|---|---|---|
| **Workspace** | Delegated workspace management on top of Team Folders | When department leads need self-service folder management |
| **Organization Folders** | Advanced Team Folder management for larger organizations | When the folder/group structure becomes complex |
| **CiviCRM Integration** | Attach files to CRM contacts | If the nonprofit adopts CiviCRM for donor/alumni management |
| **DocuDesk** | Publication consent tracking and document metadata | When media rights tracking needs formal workflow |
| **OCR (Tesseract)** | Optical character recognition for scanned documents | When the archive has a significant volume of scanned paper |

---

## Cron Schedule

Several apps require periodic background tasks. Nextcloud AIO manages its own cron container, but these additional jobs should be scheduled.

Create a cron job on the host (or use the AIO cron container):

```bash
# /etc/cron.d/nextcloud-archive
OCC="docker exec --user www-data nextcloud-aio-nextcloud php occ"

# Memories: re-index new media every 15 minutes
*/15 * * * * root $OCC memories:index > /dev/null 2>&1

# Preview Generator: generate previews for new files every 10 minutes
*/10 * * * * root $OCC preview:pre-generate > /dev/null 2>&1

# Full text search: index new content every 30 minutes
*/30 * * * * root $OCC fulltextsearch:index > /dev/null 2>&1
```

Or use the provided `index-media.sh` script which runs all indexing tasks in sequence:

```bash
# Run all indexing once per hour
0 * * * * root /path/to/steffi-nossen-archive/scripts/index-media.sh > /dev/null 2>&1
```

See the script documentation for details.
