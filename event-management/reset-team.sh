#!/bin/bash
# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# Full reset of team environment (stop, remove, recreate)

if [ -z "$1" ]; then
    echo "Usage: $0 <team_number>"
    echo "Example: $0 001"
    exit 1
fi

TEAM_ID=$(printf "team%d" $1)

echo "=== Full Reset Team $1 ==="
echo "Time: $(date)"
echo ""
echo "⚠️  WARNING: This will STOP and REMOVE all containers for team $1"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

echo "Stopping containers..."
docker stop $(docker ps --filter "name=$TEAM_ID" -q) 2>/dev/null

echo "Removing containers..."
docker rm $(docker ps -a --filter "name=$TEAM_ID" -q) 2>/dev/null

echo ""
echo "Recreating team $1 containers..."

# Find deployment directory relative to script location
DEPLOY_DIR="$SCRIPT_DIR/../deployment"

if [ ! -d "$DEPLOY_DIR" ]; then
    echo "❌ Error: deployment directory not found at $DEPLOY_DIR"
    exit 1
fi

# Run deployment for single team
cd "$DEPLOY_DIR"
sudo bash deploy-cloud-hardened.sh 1 $1

echo ""
echo "✓ Team $1 reset complete"
