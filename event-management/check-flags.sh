#!/bin/bash
# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# Verify flag accessibility for all teams

echo "=== Flag Accessibility Check ==="
echo "Time: $(date)"
echo ""

if [ -n "$1" ]; then
    TEAMS=$1
else
    TEAMS="001 002 003 004 005"
fi

for team_num in $TEAMS; do
    TEAM_ID=$(printf "team%03d" $team_num)
    
    echo "Team $team_num:"
    
    # Check breaker v1
    V1_CONTAINER="${TEAM_ID}-breaker-v1"
    if docker ps --format "{{.Names}}" | grep -q "^${V1_CONTAINER}$"; then
        # Try to get breaker status
        STATUS=$(docker exec $V1_CONTAINER curl -s http://localhost:9000/status 2>/dev/null | grep -o "FLAG{[^}]*}" || echo "No flag")
        echo "  v1: $STATUS"
    else
        echo "  v1: ❌ Container not running"
    fi
    
    # Check breaker v2
    V2_CONTAINER="${TEAM_ID}-breaker-v2"
    if docker ps --format "{{.Names}}" | grep -q "^${V2_CONTAINER}$"; then
        STATUS=$(docker exec $V2_CONTAINER curl -s http://localhost:9000/status 2>/dev/null | grep -o "FLAG{[^}]*}" || echo "No flag")
        echo "  v2: $STATUS"
    else
        echo "  v2: ❌ Container not running"
    fi
    
    echo ""
done

echo "✓ Check complete"
