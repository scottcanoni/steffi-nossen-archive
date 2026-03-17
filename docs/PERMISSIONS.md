# Permissions & Folder Structure

This document describes the Nextcloud groups, Team Folders, and access control rules that make up the archive's permission model.

## Guiding Principles

1. **Folder structure is the browsing experience.** What you see in the file tree is how you navigate the archive.
2. **Editors write to intake folders, not the archive.** New material goes into `Uploads/`. Admins curate it into `Archive/`.
3. **Keep ACLs flat.** Top-level permission zones are easier to reason about. Avoid deeply nested permission exceptions.
4. **Public access uses share links, not accounts.** The public never logs in.

## Groups

Create these Nextcloud groups after first login:

| Group | Purpose |
|---|---|
| `admins` | Full control. Manages users, folders, shares, backups, and server. 2FA enforced. |
| `viewers-private` | Read-only access to most archive content. Logged-in users only. |
| `editors-uploads` | Can upload new material to `Uploads/` subfolders. 2FA enforced. |
| `editors-alumni` | Can upload to alumni-specific areas within `Uploads/`. 2FA enforced. |

### Creating Groups

In the Nextcloud admin panel:

1. Go to **Users** (top-right menu)
2. Click **Add group** in the left sidebar
3. Create each group listed above

Or via the command line:

```bash
docker exec --user www-data nextcloud-aio-nextcloud \
  php occ group:add admins

docker exec --user www-data nextcloud-aio-nextcloud \
  php occ group:add viewers-private

docker exec --user www-data nextcloud-aio-nextcloud \
  php occ group:add editors-uploads

docker exec --user www-data nextcloud-aio-nextcloud \
  php occ group:add editors-alumni
```

## Team Folders

Team Folders (formerly Group Folders) are the backbone of the archive. They are admin-managed shared folders visible to specific groups.

### Creating Team Folders

Enable the **Group Folders** app first (see [APPS.md](APPS.md)), then create each folder:

```bash
OCC="docker exec --user www-data nextcloud-aio-nextcloud php occ"

$OCC groupfolders:create Public
$OCC groupfolders:create Archive
$OCC groupfolders:create Uploads
$OCC groupfolders:create Restricted
$OCC groupfolders:create Admin
```

### Folder-to-Group Permissions Matrix

Each cell shows the permissions granted. An empty cell means no access.

| Folder | `admins` | `viewers-private` | `editors-uploads` | `editors-alumni` | Public (share links) |
|---|---|---|---|---|---|
| **Public** | Read, Write, Delete, Share | Read | Read | Read | Read (via link) |
| **Archive** | Read, Write, Delete, Share | Read | -- | -- | -- |
| **Uploads** | Read, Write, Delete, Share | -- | Write, Read (own subfolder) | Write, Read (own subfolder) | -- |
| **Restricted** | Read, Write, Delete, Share | Read (selected content) | -- | -- | -- |
| **Admin** | Read, Write, Delete, Share | -- | -- | -- | -- |

### Assigning Groups to Team Folders

After creating each Team Folder, assign the groups and their permission levels.

Via the command line (folder IDs are returned when creating them -- use `groupfolders:list` to look them up):

```bash
OCC="docker exec --user www-data nextcloud-aio-nextcloud php occ"

# Get folder IDs
$OCC groupfolders:list

# Public folder (assuming ID 1)
$OCC groupfolders:group 1 admins write share delete
$OCC groupfolders:group 1 viewers-private read
$OCC groupfolders:group 1 editors-uploads read
$OCC groupfolders:group 1 editors-alumni read

# Archive folder (assuming ID 2)
$OCC groupfolders:group 2 admins write share delete
$OCC groupfolders:group 2 viewers-private read

# Uploads folder (assuming ID 3)
$OCC groupfolders:group 3 admins write share delete
$OCC groupfolders:group 3 editors-uploads write
$OCC groupfolders:group 3 editors-alumni write

# Restricted folder (assuming ID 4)
$OCC groupfolders:group 4 admins write share delete
$OCC groupfolders:group 4 viewers-private read

# Admin folder (assuming ID 5)
$OCC groupfolders:group 5 admins write share delete
```

Or via the web interface:

1. Go to **Administration settings** > **Group folders**
2. Click on each folder
3. Add the appropriate groups and set their permissions using the checkboxes

## Uploads Folder Structure

Inside the `Uploads/` Team Folder, create intake subfolders:

```
Uploads/
├── Incoming/           # General intake for editors-uploads
│   ├── Photos/
│   ├── Videos/
│   └── Documents/
├── Alumni/             # For editors-alumni group
│   ├── Photos/
│   └── Stories/
└── Board/              # Board-only intake (restrict via ACL)
```

Use **Advanced Permissions** (ACLs) within the Uploads Team Folder to further restrict which subfolders each editor group can access:

- `editors-uploads` → can write to `Incoming/`
- `editors-alumni` → can write to `Alumni/`
- `Board/` → restrict to `admins` only

## Archive Folder Convention

The long-term archive follows a year-and-event structure:

```
Archive/
├── 2024/
│   ├── Spring-Gala/
│   │   ├── Photos/
│   │   ├── Videos/
│   │   └── Program.pdf
│   ├── Summer-Intensive/
│   └── Winter-Showcase/
├── 2023/
│   └── ...
├── Historical/          # Pre-digital or undated material
│   ├── 1970s/
│   ├── 1980s/
│   └── Undated/
└── Documents/           # Board minutes, newsletters, etc.
    ├── Board-Minutes/
    └── Newsletters/
```

Only admins can create, move, or delete content here. Viewers get read-only access.

## Public Share Links

For content in the `Public/` folder that should be accessible without a Nextcloud account:

### Admin Settings for Share Links

1. Go to **Administration settings** > **Sharing**
2. Configure these policies:
   - **Enforce password protection** for public links: Recommended ON for most content
   - **Set default expiration date**: Recommended ON (e.g., 90 days)
   - **Allow uploads via public link**: OFF (use editor accounts for uploads)
   - **Allow resharing**: OFF

### Creating a Public Link

1. Navigate to the file or folder in the `Public/` Team Folder
2. Click the share icon
3. Click **Create a new share link**
4. Set a password if required by policy
5. Set an expiration date
6. Set permissions to **Read only**
7. Copy and distribute the link

### File Drop Links (Upload-Only)

For collecting material from people without accounts (e.g., event attendees submitting photos):

1. Create a folder under `Uploads/Incoming/`
2. Share it with a public link
3. Set permissions to **File drop (upload only)**
4. Set a password and expiration date

Contributors can upload but cannot see other people's uploads.

## Files Access Control Rules

The **Files Access Control** app (see [APPS.md](APPS.md)) adds rule-based enforcement beyond folder permissions. Configure these rules in **Administration settings** > **Flow**:

### Recommended Rules

1. **Block downloads from Restricted folder for non-admins**
   - Condition: File is in `Restricted/` AND user is not in group `admins`
   - Action: Block download

2. **Block delete on Archive for non-admins**
   - Condition: File is in `Archive/` AND user is not in group `admins`
   - Action: Block delete

3. **Block sharing from Restricted folder**
   - Condition: File is in `Restricted/`
   - Action: Block sharing (only admins should decide what leaves Restricted)

## Files Automated Tagging Rules

The **Files Automated Tagging** app auto-applies collaborative tags based on rules. Configure in **Administration settings** > **Flow**:

### Recommended Tags and Rules

| Tag | Applied When | Purpose |
|---|---|---|
| `incoming` | File uploaded to `Uploads/` | Marks new content for admin review |
| `public-ready` | File is in `Public/` | Confirms content is cleared for sharing |
| `restricted` | File is in `Restricted/` | Flags sensitive content |
| `needs-review` | File uploaded by `editors-alumni` | Alumni content should be reviewed before archiving |

Create the tags first in **Administration settings** > **Basic settings** > **Collaborative tags** (they must be "invisible" or "restricted" tags so that non-admins cannot remove them).

## 2FA Enforcement

Enforce TOTP two-factor authentication for privileged groups:

1. Enable the **Two-Factor TOTP Provider** app
2. Go to **Administration settings** > **Security**
3. Under **Enforce two-factor authentication**, add:
   - `admins`
   - `editors-uploads`
   - `editors-alumni`
4. `viewers-private` can be left optional unless the organization requires it

## Adding a New User -- Quick Reference

1. Go to **Users** in the admin panel
2. Click **New user**
3. Fill in username, display name, email, password
4. Add them to the appropriate group(s)
5. They will see the Team Folders assigned to their group(s) automatically
6. If in an enforced 2FA group, they will be prompted to set up TOTP on first login

See [RUNBOOK.md](RUNBOOK.md) for detailed user management procedures.
