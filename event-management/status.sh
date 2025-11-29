#!/bin/bash
# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# Check status of all CTF containers

echo "=== CTF Environment Status ==="
echo "Time: $(date)"
echo ""

if [ -n "$1" ]; then
    # Show specific team
    echo "Team: $1"
    docker ps --filter "name=$1" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    # Show SCADA systems
    echo "SCADA Systems:"
    docker ps --filter "name=openplc" --filter "name=scadabr" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
    # Show all teams
    echo "All Teams:"
    docker ps --filter "name=team" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | sort
    
    echo ""
    echo "IED Containers:"
    docker ps --filter "name=substation" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
    echo "Summary:"
    TOTAL=$(docker ps -a --filter "name=team" -q | wc -l)
    RUNNING=$(docker ps --filter "name=team" -q | wc -l)
    SCADA_TOTAL=$(docker ps -a --filter "name=openplc" -q | wc -l)
    SCADA_TOTAL=$((SCADA_TOTAL + $(docker ps -a --filter "name=scadabr" -q | wc -l)))
    SCADA_RUNNING=$(docker ps --filter "name=openplc" -q | wc -l)
    SCADA_RUNNING=$((SCADA_RUNNING + $(docker ps --filter "name=scadabr" -q | wc -l)))
    
    echo "Teams: $RUNNING / $TOTAL containers"
    echo "SCADA: $SCADA_RUNNING / $SCADA_TOTAL containers"
    
    if [ $RUNNING -ne $TOTAL ] || [ $SCADA_RUNNING -ne $SCADA_TOTAL ]; then
        echo ""
        echo "⚠️  WARNING: Some containers are not running!"
        docker ps -a --filter "name=team" --filter "status=exited" --format "{{.Names}}"
        docker ps -a --filter "name=openplc" --filter "status=exited" --format "{{.Names}}"
        docker ps -a --filter "name=scadabr" --filter "status=exited" --format "{{.Names}}"
    fi
fi
