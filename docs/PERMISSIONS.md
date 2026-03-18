# Permissions and Access

This document describes how user access is managed in the Immich-based archive.

## Guiding Principles

1. **Simple roles**: Public, Viewer, Editor, Admin -- mapped to Immich's native user and sharing model.
2. **Editors upload to their own library**: New material goes into the editor's personal uploads. Admins curate it into shared albums.
3. **Public access uses shared links, not accounts**: The public never logs in.
4. **External Libraries preserve folder structure**: Existing organized folders on disk appear in Immich without re-uploading.

## Role Definitions

### Admin
- The first account created during setup becomes admin
- Full control: user management, server settings, libraries, albums, all media
- Can create and manage External Libraries
- Can disable/enable ML features (face detection, CLIP search)
- Keep this group very small (2-3 people maximum)

### Editor
- Standard Immich user account
- Can upload photos and videos to their own library
- Can be added as a collaborator on shared albums (with upload rights)
- Cannot access other users' libraries directly
- Cannot change server settings

### Viewer
- Standard Immich user account with limited purpose
- Receives shared albums from admins (read-only)
- Can browse shared albums and view media
- Cannot upload unless explicitly given collaborator access on an album

### Public
- No account required
- Access via shared links (URLs) created by admins or editors
- Optionally password-protected
- Optionally time-limited (expiration date)
- Read-only: can view and download, cannot upload or modify

## Setting Up Users

### Creating the Admin Account

On first launch, navigate to `http://localhost:2283` (local) or `https://your-domain.org` (production). The first account you create is the admin.

### Creating Additional Users

1. Log in as admin
2. Go to **Administration** (gear icon) > **User Management**
3. Click **Create User**
4. Fill in name, email, and password
5. The user can now log in and upload to their own library

### Granting Viewer-Only Access

Immich does not have a built-in "viewer-only" user type. To create a viewer:

1. Create a standard user account
2. Share albums with them (they will see shared albums in their sidebar)
3. Optionally, set a storage quota of 0 to prevent uploads (if supported in your Immich version), or simply instruct them not to upload

For truly read-only public access, use shared links instead of user accounts.

## Shared Albums

Shared albums are the primary way to organize and distribute media in Immich.

### Creating a Shared Album

1. Go to **Albums** in the sidebar
2. Click **Create Album**
3. Name it (e.g., "Spring Gala 2024", "Historical Photos 1970s")
4. Add photos from the timeline or library
5. Click the share icon to add users or create a public link

### Sharing an Album with Users

1. Open the album
2. Click the share icon
3. Search for a user by name or email
4. Choose their permission level:
   - **Viewer**: Can view but not add photos
   - **Editor/Collaborator**: Can add photos to the album

### Creating a Public Shared Link

1. Open the album
2. Click the share icon
3. Click **Create Link**
4. Configure options:
   - **Password**: Recommended for sensitive content
   - **Expiration**: Set a date when the link stops working
   - **Allow downloads**: Toggle on/off
   - **Show metadata**: Toggle on/off
5. Copy the link and distribute (email, website, social media)

## External Libraries

External Libraries let Immich watch existing folders on the server's filesystem. This is how the archive's existing folder structure gets into Immich without re-uploading everything.

### How It Works

1. Organize photos/videos on disk in a folder structure:
   ```
   /mnt/archive/external/
   ├── 2024/
   │   ├── Spring-Gala/
   │   │   ├── Photos/
   │   │   └── Videos/
   │   └── Summer-Intensive/
   ├── 2023/
   │   └── ...
   └── Historical/
       ├── 1970s/
       └── 1980s/
   ```

2. In the `docker-compose.yml`, this path is mounted read-only into the Immich container:
   ```yaml
   volumes:
     - /mnt/archive/external:/mnt/archive/external:ro
   ```

3. In the Immich admin panel, create an External Library pointing to `/mnt/archive/external`

4. Immich scans the folder, generates thumbnails, extracts metadata, and makes everything searchable -- without moving or copying files

### Adding New Content to the External Library

To add new photos to the external library:

1. Copy or move files into the folder structure on disk (via rsync, scp, USB, etc.)
2. In Immich, trigger a library rescan: **Administration** > **External Libraries** > **Scan**
3. New files appear in the timeline and search

### When to Use External Libraries vs. Uploads

- **External Library**: For the curated, organized archive that admins maintain on disk. Read-only in Immich.
- **Uploads**: For new material coming in from editors. Managed through Immich's UI.

## Suggested Album Structure

Map the archive's organizational structure to albums:

- **By event**: "Spring Gala 2024", "Winter Showcase 2023"
- **By year**: "Archive 2024", "Archive 2023"
- **By category**: "Historical Photos", "Board Events", "Alumni"
- **By access level**: "Public Highlights" (shared via link), "Internal Archive" (shared with viewer accounts)

## Admin Workflow: Curating Uploads into the Archive

1. Editor uploads photos through the Immich web or mobile app
2. Admin reviews uploads in the editor's shared album or directly
3. Admin downloads selected photos and places them into the external library folder structure on disk
4. Admin triggers a library rescan
5. Photos are now part of the permanent archive

Alternatively, admins can create shared albums directly from uploaded content without moving files to the external library. The external library approach is better for long-term preservation since the folder structure on disk is the source of truth.

## Disabling Face Recognition

If the organization's policies require it, face recognition can be disabled:

1. Go to **Administration** > **Machine Learning**
2. Toggle **Facial Recognition** off
3. Existing face data is retained but no new faces are detected

CLIP-based search can remain enabled independently of face recognition.
