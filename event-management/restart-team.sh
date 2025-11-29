#!/bin/bash
# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# Restart specific team's containers

if [ -z "$1" ]; then
    echo "Usage: $0 <team_number>"
    echo "Example: $0 001"
    exit 1
fi

TEAM_ID=$(printf "team%03d" $1)

echo "=== Restarting Team $1 ==="
echo "Time: $(date)"
echo ""

# Check if team exists
if ! docker ps -a --filter "name=$TEAM_ID" --format "{{.Names}}" | grep -q "$TEAM_ID"; then
    echo "❌ Error: Team $1 not found"
    exit 1
fi

echo "Containers to restart:"
docker ps -a --filter "name=$TEAM_ID" --format "{{.Names}}"
echo ""

docker restart $(docker ps -a --filter "name=$TEAM_ID" -q)

echo ""
echo "Waiting for containers to start..."
sleep 3

echo ""
echo "Status:"
docker ps --filter "name=$TEAM_ID" --format "table {{.Names}}\t{{.Status}}"

echo ""
echo "✓ Team $1 restarted"
