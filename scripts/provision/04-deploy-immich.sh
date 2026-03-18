#!/usr/bin/env bash
set -euo pipefail

# Deploy Immich using Docker Compose.
# Run from the repository root directory.
# Assumes Docker is installed (03-docker-install.sh) and .env is configured.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root." >&2
  exit 1
fi

ENV_FILE="$REPO_ROOT/.env"
COMPOSE_FILE="$REPO_ROOT/docker-compose.yml"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: .env file not found at $ENV_FILE" >&2
  echo "Copy .env.example to .env and fill in your values first:" >&2
  echo "  cp $REPO_ROOT/.env.example $ENV_FILE" >&2
  exit 1
fi

source "$ENV_FILE"

echo "==> Pre-flight checks..."

if [[ ! -d "$(dirname "$UPLOAD_LOCATION")" ]]; then
  echo "ERROR: Parent directory for UPLOAD_LOCATION does not exist." >&2
  echo "Ensure /mnt/archive is mounted (run 02-raid-setup.sh or 02a-raid-recover.sh first)." >&2
  exit 1
fi

if ! docker info &>/dev/null; then
  echo "ERROR: Docker is not running." >&2
  echo "Run 03-docker-install.sh first." >&2
  exit 1
fi

echo "==> Creating storage directories..."
mkdir -p "$UPLOAD_LOCATION"
mkdir -p "$EXTERNAL_LIBRARY"
mkdir -p "$DB_DATA_LOCATION"

echo "    Upload location:    $UPLOAD_LOCATION"
echo "    External library:   $EXTERNAL_LIBRARY"
echo "    Database location:  $DB_DATA_LOCATION"
echo "    Domain:             $IMMICH_DOMAIN"
echo ""

echo "==> Pulling container images..."
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" pull

echo "==> Starting Immich..."
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

echo ""
echo "==> Deployment started."
echo ""
echo "Next steps:"
echo "  1. Open https://$IMMICH_DOMAIN in your browser"
echo "  2. Create the admin account (first user becomes admin)"
echo "  3. Go to Administration > External Libraries to import existing photos"
echo "  4. Share albums or create public links as needed"
