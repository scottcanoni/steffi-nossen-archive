#!/usr/bin/env bash
set -euo pipefail

# Deploy Nextcloud AIO using Docker Compose.
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

if [[ ! -d "$NEXTCLOUD_DATADIR" ]]; then
  echo "ERROR: Data directory $NEXTCLOUD_DATADIR does not exist." >&2
  echo "Run 02-raid-setup.sh first to create and mount the RAID array." >&2
  exit 1
fi

if ! docker info &>/dev/null; then
  echo "ERROR: Docker is not running." >&2
  echo "Run 03-docker-install.sh first." >&2
  exit 1
fi

echo "    Domain:    $NEXTCLOUD_DOMAIN"
echo "    Data dir:  $NEXTCLOUD_DATADIR"
echo "    Memory:    $NEXTCLOUD_MEMORY_LIMIT"
echo "    Upload:    $NEXTCLOUD_UPLOAD_LIMIT"
echo ""

echo "==> Pulling container images..."
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" pull

echo "==> Starting Nextcloud AIO..."
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

echo ""
echo "==> Deployment started."
echo ""
echo "Next steps:"
echo "  1. Open https://<server-ip>:8080 in your browser"
echo "  2. Complete the AIO setup wizard"
echo "  3. Set your domain to: $NEXTCLOUD_DOMAIN"
echo "  4. Enable desired optional containers (Talk, ClamAV, etc.)"
echo "  5. Click 'Start containers' in the AIO dashboard"
echo ""
echo "Once Nextcloud is running, access it at:"
echo "  https://$NEXTCLOUD_DOMAIN"
