#!/usr/bin/env bash
set -euo pipefail

# Run all Nextcloud indexing tasks in sequence:
#   1. Memories media index
#   2. Preview Generator (pre-generate for new files)
#   3. Full text search index (if enabled)
#
# Schedule this via cron, e.g.:
#   0 * * * * root /opt/steffi-nossen-archive/scripts/index-media.sh >> /var/log/nextcloud-index.log 2>&1

OCC="docker exec --user www-data nextcloud-aio-nextcloud php occ"
LOGPREFIX="[$(date '+%Y-%m-%d %H:%M:%S')]"

echo "$LOGPREFIX Starting indexing run..."

echo "$LOGPREFIX [1/3] Memories index..."
if $OCC memories:index 2>&1; then
  echo "$LOGPREFIX Memories index complete."
else
  echo "$LOGPREFIX WARNING: Memories index failed or app not enabled." >&2
fi

echo "$LOGPREFIX [2/3] Preview pre-generation..."
if $OCC preview:pre-generate 2>&1; then
  echo "$LOGPREFIX Preview generation complete."
else
  echo "$LOGPREFIX WARNING: Preview generation failed or app not enabled." >&2
fi

echo "$LOGPREFIX [3/3] Full text search index..."
if $OCC fulltextsearch:index 2>&1; then
  echo "$LOGPREFIX Full text search index complete."
else
  echo "$LOGPREFIX WARNING: Full text search index failed or not enabled." >&2
fi

echo "$LOGPREFIX Indexing run finished."
