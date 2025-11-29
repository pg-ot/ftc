#!/bin/bash
# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# Reset specific breaker container

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <team_number> <version>"
    echo "Example: $0 001 v1"
    echo "         $0 001 v2"
    exit 1
fi

TEAM_ID=$(printf "team%03d" $1)
VERSION=$2
CONTAINER="${TEAM_ID}-breaker-${VERSION}"

echo "=== Resetting Breaker: $CONTAINER ==="
echo "Time: $(date)"
echo ""

if ! docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER}$"; then
    echo "❌ Error: Container $CONTAINER not found"
    exit 1
fi

echo "Restarting $CONTAINER..."
docker restart $CONTAINER

sleep 2

echo ""
echo "Status:"
docker ps --filter "name=$CONTAINER" --format "table {{.Names}}\t{{.Status}}"

echo ""
echo "✓ Breaker reset complete"
