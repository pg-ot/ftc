#!/bin/bash
# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# Verify network connectivity between containers

if [ -z "$1" ]; then
    TEAM="1"
else
    TEAM=$1
fi

# Handle "ALL" option
if [ "$TEAM" = "ALL" ]; then
    echo "=== Network Check for All Teams ==="
    echo "Time: $(date)"
    echo ""
    
    # Get deployed teams dynamically
    DEPLOYED_TEAMS=($(docker ps --filter "name=team" --format "{{.Names}}" | grep -o "team[0-9]\+" | sort -u | sed 's/team//'))
    
    for TEAM_NUM in "${DEPLOYED_TEAMS[@]}"; do
        echo "Checking Team $TEAM_NUM..."
        $0 $TEAM_NUM | grep -E "(✓|✗)"
        echo ""
    done
    
    echo "✓ All teams checked"
    exit 0
fi

TEAM_ID="team${TEAM}"

echo "=== Network Connectivity Check: Team $TEAM ==="
echo "Time: $(date)"
echo ""

# Check if containers exist
KALI="${TEAM_ID}-kali"
BREAKER_V1="${TEAM_ID}-breaker-v1"
BREAKER_V2="${TEAM_ID}-breaker-v2"
CONTROL="${TEAM_ID}-control-ied"

echo "Testing from Kali workstation..."
echo ""

# Test ping to breakers
echo "1. Ping breaker-v1:"
docker exec $KALI ping -c 2 $BREAKER_V1 2>/dev/null && echo "   ✓ Success" || echo "   ✗ Failed"

echo ""
echo "2. Ping breaker-v2:"
docker exec $KALI ping -c 2 $BREAKER_V2 2>/dev/null && echo "   ✓ Success" || echo "   ✗ Failed"

echo ""
echo "3. Ping control IED:"
docker exec $KALI ping -c 2 $CONTROL 2>/dev/null && echo "   ✓ Success" || echo "   ✗ Failed"

echo ""
echo "4. Check GOOSE traffic:"
GOOSE_COUNT=$(docker exec $KALI timeout 5 tcpdump -i eth0 -c 5 ether proto 0x88b8 2>/dev/null | wc -l)
if [ $GOOSE_COUNT -gt 0 ]; then
    echo "   ✓ GOOSE packets detected ($GOOSE_COUNT packets)"
else
    echo "   ✗ No GOOSE traffic"
fi

echo ""
echo "5. HTTP access to breaker-v1:"
docker exec $KALI curl -s -o /dev/null -w "%{http_code}" http://$BREAKER_V1:9000/ 2>/dev/null | grep -q "200" && echo "   ✓ Success" || echo "   ✗ Failed"

echo ""
echo "✓ Network check complete"
