#!/bin/bash
# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# Emergency stop all CTF containers

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    EMERGENCY STOP                              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "⚠️  WARNING: This will STOP all team containers immediately!"
echo ""

read -p "Are you sure? Type 'STOP' to confirm: " CONFIRM

if [ "$CONFIRM" != "STOP" ]; then
    echo "Cancelled."
    exit 1
fi

echo ""
echo "Stopping all team containers..."
docker stop $(docker ps --filter "name=team" -q)

echo ""
echo "Status:"
docker ps --filter "name=team" --format "table {{.Names}}\t{{.Status}}"

echo ""
echo "✓ All containers stopped"
echo ""
echo "To restart: ./restart-all.sh"
