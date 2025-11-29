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
docker exec $KALI ping -c 2 $BREAKER_V1 2>/dev/null && echo "   ✓ $BREAKER_V1 reachable" || echo "   ✗ $BREAKER_V1 unreachable"

echo ""
echo "2. Ping breaker-v2:"
docker exec $KALI ping -c 2 $BREAKER_V2 2>/dev/null && echo "   ✓ $BREAKER_V2 reachable" || echo "   ✗ $BREAKER_V2 unreachable"

echo ""
echo "3. Ping control IED:"
docker exec $KALI ping -c 2 $CONTROL 2>/dev/null && echo "   ✓ $CONTROL reachable" || echo "   ✗ $CONTROL unreachable"

echo ""
echo "4. Ping OpenPLC:"
docker exec $KALI ping -c 2 openplc 2>/dev/null && echo "   ✓ openplc reachable" || echo "   ✗ openplc unreachable"

echo ""
echo "5. Ping ScadaBR:"
docker exec $KALI ping -c 2 ${TEAM_ID}-scadabr 2>/dev/null && echo "   ✓ ${TEAM_ID}-scadabr reachable" || echo "   ✗ ${TEAM_ID}-scadabr unreachable"

echo ""
echo "6. GOOSE publish (tcpdump on Kali):"
GOOSE_COUNT=$(docker exec $KALI timeout 5 tcpdump -i eth0 -c 5 ether proto 0x88b8 2>/dev/null | wc -l)
if [ $GOOSE_COUNT -gt 0 ]; then
    echo "   ✓ GOOSE packets detected ($GOOSE_COUNT packets)"
else
    echo "   ✗ No GOOSE traffic"
fi

echo ""
echo "7. Breaker-v1 GOOSE subscription:"
BREAKER_V1_STATUS=$(docker exec $KALI curl -s http://$BREAKER_V1:9000/status 2>/dev/null)
if echo "$BREAKER_V1_STATUS" | grep -q '"pos"'; then
    POS=$(echo "$BREAKER_V1_STATUS" | grep -o '"pos": [0-9]' | grep -o '[0-9]')
    STATUS=$([ "$POS" = "2" ] && echo "CLOSED" || echo "OPEN")
    echo "   ✓ Receiving GOOSE (Status: $STATUS, stNum: $(echo "$BREAKER_V1_STATUS" | grep -o '"stNum": [0-9]*' | grep -o '[0-9]*'))"
else
    echo "   ✗ Not receiving GOOSE"
fi

echo ""
echo "8. Breaker-v2 GOOSE subscription:"
BREAKER_V2_STATUS=$(docker exec $KALI curl -s http://$BREAKER_V2:9000/status 2>/dev/null)
if echo "$BREAKER_V2_STATUS" | grep -q '"pos"'; then
    POS=$(echo "$BREAKER_V2_STATUS" | grep -o '"pos": [0-9]' | grep -o '[0-9]')
    STATUS=$([ "$POS" = "2" ] && echo "CLOSED" || echo "OPEN")
    echo "   ✓ Receiving GOOSE (Status: $STATUS, stNum: $(echo "$BREAKER_V2_STATUS" | grep -o '"stNum": [0-9]*' | grep -o '[0-9]*'))"
else
    echo "   ✗ Not receiving GOOSE"
fi

echo ""
echo "9. Modbus test (OpenPLC:502):"
docker exec $KALI timeout 3 bash -c "cat < /dev/null > /dev/tcp/openplc/502" 2>/dev/null && echo "   ✓ openplc:502 accessible" || echo "   ✗ openplc:502 not accessible"

echo ""
echo "10. ScadaBR web access:"
docker exec $KALI curl -s -o /dev/null -w "%{http_code}" http://${TEAM_ID}-scadabr:8080/ 2>/dev/null | grep -q "200" && echo "   ✓ ${TEAM_ID}-scadabr:8080 accessible" || echo "   ✗ ${TEAM_ID}-scadabr:8080 not accessible"

echo ""
echo "✓ Network check complete"
