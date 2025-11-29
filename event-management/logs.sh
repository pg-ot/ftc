#!/bin/bash
# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# View container logs

if [ -z "$1" ]; then
    echo "Usage: $0 <container_name_or_team>"
    echo "Examples:"
    echo "  $0 team001              # All team001 containers"
    echo "  $0 team001-breaker-v1   # Specific container"
    echo "  $0 team001-kali         # Kali container"
    exit 1
fi

FILTER=$1

echo "=== Container Logs: $FILTER ==="
echo ""

# Check if it's a full container name or team prefix
if docker ps -a --format "{{.Names}}" | grep -q "^${FILTER}$"; then
    # Exact container match
    echo "Showing logs for: $FILTER"
    echo "Press Ctrl+C to exit"
    echo ""
    docker logs -f --tail=50 $FILTER
else
    # Show all matching containers
    CONTAINERS=$(docker ps -a --filter "name=$FILTER" --format "{{.Names}}")
    
    if [ -z "$CONTAINERS" ]; then
        echo "❌ No containers found matching: $FILTER"
        exit 1
    fi
    
    echo "Found containers:"
    echo "$CONTAINERS"
    echo ""
    
    # Show logs from all matching containers
    for container in $CONTAINERS; do
        echo "=== $container (last 20 lines) ==="
        docker logs --tail=20 $container
        echo ""
    done
fi
