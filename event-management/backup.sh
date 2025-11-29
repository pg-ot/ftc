#!/bin/bash
# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# Backup current container state

BACKUP_DIR="/home/svresidency_kovai/ctf-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/backup_$TIMESTAMP"

echo "=== CTF Environment Backup ==="
echo "Time: $(date)"
echo ""

mkdir -p $BACKUP_DIR

echo "Creating backup at: $BACKUP_PATH"
mkdir -p $BACKUP_PATH

# Export container list
echo "Exporting container list..."
docker ps -a --filter "name=team" --format "{{.Names}}\t{{.Status}}" > $BACKUP_PATH/containers.txt

# Export container configs
echo "Exporting container configurations..."
for container in $(docker ps -a --filter "name=team" --format "{{.Names}}"); do
    docker inspect $container > $BACKUP_PATH/${container}_config.json 2>/dev/null
done

# Export logs
echo "Exporting logs..."
mkdir -p $BACKUP_PATH/logs
for container in $(docker ps -a --filter "name=team" --format "{{.Names}}"); do
    docker logs $container > $BACKUP_PATH/logs/${container}.log 2>&1
done

# System info
echo "Saving system info..."
docker stats --no-stream > $BACKUP_PATH/system_stats.txt
df -h > $BACKUP_PATH/disk_usage.txt
free -h > $BACKUP_PATH/memory_usage.txt

echo ""
echo "✓ Backup complete: $BACKUP_PATH"
echo ""
echo "Backup contents:"
du -sh $BACKUP_PATH
ls -lh $BACKUP_PATH/
