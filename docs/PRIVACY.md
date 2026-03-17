# Privacy & Media Rights Policy

Guidelines for handling sensitive media in the Steffi Nossen archive, particularly content involving minors and content with privacy implications.

## Why This Matters

The archive contains photos and videos from dance performances, classes, and events. This routinely includes:

- Minors (students under 18)
- Backstage and rehearsal photos (informal, potentially unflattering)
- Content from private events
- Photos with identifiable location metadata (GPS coordinates in EXIF data)

The organization must decide **before launch** what can be made public and how to handle sensitive content.

## Decisions Required Before Launch

These questions should be answered by the board or organizational leadership:

1. **Can photos of minors be shared publicly?**
   - If yes, under what conditions? (e.g., performance photos only, no backstage)
   - Is parental consent required? Is there an existing consent form?
   - Does the school already collect media release forms?

2. **Should GPS/location metadata be stripped from public photos?**
   - EXIF data can reveal where photos were taken
   - Recommended: strip EXIF GPS data from anything in the `Public/` folder

3. **What about historical photos?**
   - Older photos may include people who cannot be contacted for consent
   - Define a policy: e.g., performance photos from public events are OK, backstage photos require review

4. **Who decides what goes public?**
   - Recommended: only admins can move content to `Public/`
   - Editors can flag content as "public-safe" using MetaVox metadata, but the actual move requires admin action

## Content Classification

Use the Team Folder structure and metadata tags to classify content:

| Classification | Where It Lives | Who Can See It |
|---|---|---|
| **Public** | `Public/` folder | Anyone with a share link |
| **Internal** | `Archive/` folder | `viewers-private` and `admins` only |
| **Restricted** | `Restricted/` folder | `admins` only (selective viewer access) |
| **Incoming** | `Uploads/` folder | Uploading editor + `admins` |

### What Goes in Restricted

- Photos of minors that have not been cleared for public use
- Backstage/rehearsal content
- Content where consent status is unknown
- Internal organizational documents
- Anything an admin is unsure about (err on the side of restriction)

## EXIF Metadata Stripping

Photos from smartphones and cameras often contain embedded metadata including:

- GPS coordinates (location where the photo was taken)
- Camera model and serial number
- Date and time
- Thumbnail of the original image

### Stripping EXIF from Public Content

Before moving content to the `Public/` folder, strip sensitive EXIF data. Install `exiftool` on the server:

```bash
sudo apt-get install libimage-exiftool-perl
```

Strip GPS and identifying metadata while preserving useful fields (date, orientation):

```bash
# Strip GPS data from a single file
exiftool -GPS:all= -EXIF:SerialNumber= photo.jpg

# Strip GPS data from an entire folder recursively
exiftool -GPS:all= -EXIF:SerialNumber= -r /mnt/archive/__groupfolders/1/Public/

# Preview what would be removed (dry run)
exiftool -GPS:all= -EXIF:SerialNumber= -r -overwrite_original_in_place -v /path/to/folder
```

### Automated Stripping

Consider adding EXIF stripping to the admin workflow: before moving files from `Uploads/` to `Public/`, run the strip command. This could be scripted if the volume justifies it.

### What to Keep

Some EXIF data is useful for the archive:
- **Date/time**: Essential for timeline organization in Memories
- **Orientation**: Needed for correct photo display
- **Camera model**: Sometimes useful for archival purposes

Only strip GPS, serial numbers, and other personally identifying fields.

## Minors Policy -- Recommended Framework

### If the School Has Existing Media Release Forms

1. Continue using the existing consent process
2. Only move content to `Public/` if consent covers digital/online distribution
3. Store consent records in the `Admin/` Team Folder or in the school's existing records system
4. Tag unconsented content as `restricted` using automated tagging

### If No Existing Consent Process

1. Treat all content with identifiable minors as `Restricted/` by default
2. Work with the board to create a media release form for future events
3. Historical content: performance photos from public events may be treated as implicitly consented (check with legal counsel)
4. Backstage, classroom, and informal content with minors stays in `Restricted/` unless specific consent is obtained

### Practical Guidelines for Admins

- **When in doubt, restrict.** It is much easier to make something public later than to un-publish something.
- **Performance photos from ticketed public events** are generally the safest category for public sharing.
- **Class photos and backstage content** are the highest risk category and should default to restricted.
- **Group photos** where individuals are not prominently featured are lower risk than solo/featured shots.

## Data Retention

Consider establishing a retention policy:

- **Archive content**: Kept indefinitely (this is an archive)
- **Uploads/Incoming**: Cleared after review (admin moves to Archive or deletes)
- **Deleted files**: Nextcloud trash retains deleted files for 30 days by default
- **Share links**: Expire automatically if expiration dates are enforced
- **User accounts**: Disabled (not deleted) when people leave the organization

## Annual Review

Once per year, the admin team should:

1. Review what is in the `Public/` folder and confirm it still meets the organization's comfort level
2. Review active share links and disable any that are no longer needed
3. Audit the `Restricted/` folder for content that may have been cleared for release
4. Confirm that the minors policy is still aligned with the school's current consent practices
5. Update this document if policies change
