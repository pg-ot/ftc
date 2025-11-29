#!/bin/bash
# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# Restart all CTF containers

echo "=== Restarting All CTF Containers ==="
echo "Time: $(date)"
echo ""

read -p "This will restart ALL team containers. Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

echo "Restarting all team containers..."
docker restart $(docker ps -a --filter "name=team" -q)

echo ""
echo "Waiting for containers to start..."
sleep 5

echo ""
echo "Status:"
docker ps --filter "name=team" --format "table {{.Names}}\t{{.Status}}" | head -20

echo ""
echo "✓ Restart complete"
