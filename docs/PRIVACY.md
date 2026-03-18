# Privacy and Media Rights Policy

Guidelines for handling sensitive media in the Steffi Nossen archive, particularly content involving minors and content with privacy implications.

## Why This Matters

The archive contains photos and videos from dance performances, classes, and events. This routinely includes:

- Minors (students under 18)
- Backstage and rehearsal photos (informal, potentially unflattering)
- Content from private events
- Photos with identifiable location metadata (GPS coordinates in EXIF data)
- Photos where faces are automatically recognized by Immich's ML

The organization must decide **before launch** what can be made public and how to handle sensitive content.

## Decisions Required Before Launch

These questions should be answered by the board or organizational leadership:

1. **Can photos of minors be shared publicly?**
   - If yes, under what conditions? (e.g., performance photos only, no backstage)
   - Is parental consent required? Is there an existing consent form?
   - Does the school already collect media release forms?

2. **Should GPS/location metadata be stripped from public photos?**
   - EXIF data can reveal where photos were taken
   - Recommended: strip EXIF GPS data from anything shared via public links

3. **What about historical photos?**
   - Older photos may include people who cannot be contacted for consent
   - Define a policy: e.g., performance photos from public events are OK, backstage photos require review

4. **Who decides what goes public?**
   - Recommended: only admins create shared links for public access
   - Editors can suggest content, but public sharing requires admin action

5. **Should face recognition be enabled?**
   - Immich can automatically detect and group faces in photos
   - This is useful for finding all photos of a specific person
   - Some organizations may have concerns about biometric data collection
   - Face recognition can be disabled globally in admin settings

## Content Classification

Use albums and sharing to classify content:

- **Public** (shared via links): Content cleared for anyone to view
- **Internal** (shared albums with viewer accounts): Content for staff and trusted users
- **Restricted** (admin-only albums): Sensitive content -- minors, backstage, rights-unclear
- **Incoming** (editor uploads): New material awaiting admin review

## EXIF Metadata Stripping

Photos from smartphones and cameras often contain embedded metadata including:

- GPS coordinates (location where the photo was taken)
- Camera model and serial number
- Date and time
- Thumbnail of the original image

### Stripping EXIF Before Public Sharing

Before creating public shared links for sensitive content, strip GPS data. Install `exiftool` on the server:

```bash
sudo apt-get install libimage-exiftool-perl
```

Strip GPS and identifying metadata while preserving useful fields (date, orientation):

```bash
# Strip GPS data from a single file
exiftool -GPS:all= -EXIF:SerialNumber= photo.jpg

# Strip GPS data from an entire folder recursively
exiftool -GPS:all= -EXIF:SerialNumber= -r /mnt/archive/external/Public/
```

Note: Immich shared links include an option to **show or hide metadata**. Toggling metadata off in the shared link settings prevents viewers from seeing EXIF data, but the data still exists in the file if they download it.

### What to Keep

Some EXIF data is useful for the archive:
- **Date/time**: Essential for timeline organization
- **Orientation**: Needed for correct photo display
- **Camera model**: Sometimes useful for archival purposes

Only strip GPS, serial numbers, and other personally identifying fields.

## Face Recognition Considerations

Immich's face recognition is a powerful archival tool but raises privacy questions:

### Benefits
- Find all photos of a specific person across the entire archive
- Useful for alumni searching for their own photos
- Makes the archive much more usable over time

### Concerns
- Biometric data collection (face embeddings are stored in the database)
- Photos of minors are automatically processed
- Named face data could be sensitive

### Recommendation

- **Enable face recognition** for the admin and internal use -- it makes the archive far more useful
- **Do not expose face/people data** in public shared links
- **If the organization requires it**, disable face recognition entirely in admin settings
- Document the decision in the organization's privacy policy

## Minors Policy -- Recommended Framework

### If the School Has Existing Media Release Forms

1. Continue using the existing consent process
2. Only create public shared links for content where consent covers digital/online distribution
3. Store consent records securely (physical files or a separate system)

### If No Existing Consent Process

1. Treat all content with identifiable minors as restricted by default
2. Work with the board to create a media release form for future events
3. Historical content: performance photos from public events may be treated as implicitly consented (check with legal counsel)
4. Backstage, classroom, and informal content with minors stays restricted unless specific consent is obtained

### Practical Guidelines for Admins

- **When in doubt, restrict.** It is much easier to make something public later than to un-publish something.
- **Performance photos from ticketed public events** are generally the safest category for public sharing.
- **Class photos and backstage content** are the highest risk category and should default to restricted.
- **Group photos** where individuals are not prominently featured are lower risk than solo/featured shots.

## Data Retention

Consider establishing a retention policy:

- **Archive content**: Kept indefinitely (this is an archive)
- **Editor uploads**: Reviewed by admin, then curated into albums or deleted
- **Deleted photos**: Immich trash retains deleted items for 30 days by default
- **Shared links**: Set expiration dates, review periodically
- **User accounts**: Disable (not delete) when people leave the organization

## Annual Review

Once per year, the admin team should:

1. Review active shared links and disable any that are no longer needed
2. Confirm that the minors policy is still aligned with the school's current consent practices
3. Review face recognition data and remove any names that should not be stored
4. Check that public-facing content still meets the organization's comfort level
5. Update this document if policies change
