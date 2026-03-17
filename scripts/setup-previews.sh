#!/usr/bin/env bash
set -euo pipefail

# Configure Nextcloud Preview Generator settings and run the initial
# full preview generation pass.
#
# Run this ONCE after installing the Preview Generator app.
# Subsequent preview generation is handled by cron (see index-media.sh).

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root." >&2
  exit 1
fi

OCC="docker exec --user www-data nextcloud-aio-nextcloud php occ"

echo "==> Configuring preview sizes..."

# Square thumbnails (used in grid views)
$OCC config:app:set previewgenerator squareSizes --value="32 64 256 512 1024"

# Width-based previews (used in file listings)
$OCC config:app:set previewgenerator widthSizes --value="64 128 256 512 1024 2048"

# Height-based previews (used in some views)
$OCC config:app:set previewgenerator heightSizes --value="64 128 256 512 1024 2048"

echo "==> Configuring system preview limits..."

$OCC config:system:set preview_max_x --value 2048
$OCC config:system:set preview_max_y --value 2048
$OCC config:system:set preview_max_filesize_image --value 256

echo "==> Enabling preview providers for archive media types..."

$OCC config:system:set enabledPreviewProviders 0 --value="OC\Preview\PNG"
$OCC config:system:set enabledPreviewProviders 1 --value="OC\Preview\JPEG"
$OCC config:system:set enabledPreviewProviders 2 --value="OC\Preview\GIF"
$OCC config:system:set enabledPreviewProviders 3 --value="OC\Preview\BMP"
$OCC config:system:set enabledPreviewProviders 4 --value="OC\Preview\XBitmap"
$OCC config:system:set enabledPreviewProviders 5 --value="OC\Preview\MP3"
$OCC config:system:set enabledPreviewProviders 6 --value="OC\Preview\TXT"
$OCC config:system:set enabledPreviewProviders 7 --value="OC\Preview\MarkDown"
$OCC config:system:set enabledPreviewProviders 8 --value="OC\Preview\OpenDocument"
$OCC config:system:set enabledPreviewProviders 9 --value="OC\Preview\Krita"
$OCC config:system:set enabledPreviewProviders 10 --value="OC\Preview\HEIC"
$OCC config:system:set enabledPreviewProviders 11 --value="OC\Preview\Movie"
$OCC config:system:set enabledPreviewProviders 12 --value="OC\Preview\MKV"
$OCC config:system:set enabledPreviewProviders 13 --value="OC\Preview\MP4"
$OCC config:system:set enabledPreviewProviders 14 --value="OC\Preview\AVI"

echo "==> Running initial full preview generation..."
echo "    This may take a very long time on a large archive."
echo "    You can safely Ctrl+C and re-run later; it picks up where it left off."
echo ""

$OCC preview:generate-all

echo "==> Preview setup complete."
echo "    Ongoing generation is handled by cron via index-media.sh."
