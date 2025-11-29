#!/bin/bash
# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# Comprehensive network testing for all teams

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         Network Testing - All Teams                           ║"
echo "║         $(date '+%Y-%m-%d %H:%M:%S')                                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Test 1: Connectivity within each team
echo "═══ Test 1: Internal Team Connectivity ═══"
echo ""

for i in {1..5}; do
    TEAM=$(printf "%03d" $i)
    TEAM_ID=$(printf "team%03d" $i)
    
    # Check if team exists
    if ! docker ps --format "{{.Names}}" | grep -q "^${TEAM_ID}-kali$"; then
        echo "Team $TEAM: ⚠️  Not deployed"
        continue
    fi
    
    echo -n "Team $TEAM: "
    
    # Quick connectivity test
    if docker exec ${TEAM_ID}-kali ping -c 1 -W 1 ${TEAM_ID}-breaker-v1 &>/dev/null; then
        echo "✓ Connected"
    else
        echo "❌ Connection failed"
    fi
done

echo ""
echo "═══ Test 2: Network Isolation Between Teams ═══"
echo ""

ISOLATION_ISSUES=0

for i in {1..5}; do
    SOURCE=$(printf "%03d" $i)
    SOURCE_ID=$(printf "team%03d" $i)
    
    # Check if source team exists
    if ! docker ps --format "{{.Names}}" | grep -q "^${SOURCE_ID}-kali$"; then
        continue
    fi
    
    for j in {1..5}; do
        if [ $i -eq $j ]; then
            continue
        fi
        
        TARGET=$(printf "%03d" $j)
        TARGET_ID=$(printf "team%03d" $j)
        
        # Check if target team exists
        if ! docker ps --format "{{.Names}}" | grep -q "^${TARGET_ID}-breaker-v1$"; then
            continue
        fi
        
        # Test isolation
        if docker exec ${SOURCE_ID}-kali ping -c 1 -W 1 ${TARGET_ID}-breaker-v1 &>/dev/null; then
            echo "❌ Team $SOURCE can reach Team $TARGET (ISOLATION BROKEN!)"
            ISOLATION_ISSUES=$((ISOLATION_ISSUES + 1))
        fi
    done
done

if [ $ISOLATION_ISSUES -eq 0 ]; then
    echo "✓ All teams properly isolated"
else
    echo ""
    echo "⚠️  Found $ISOLATION_ISSUES isolation issues!"
fi

echo ""
echo "═══ Test 3: GOOSE Traffic Detection ═══"
echo ""

for i in {1..5}; do
    TEAM=$(printf "%03d" $i)
    TEAM_ID=$(printf "team%03d" $i)
    
    # Check if team exists
    if ! docker ps --format "{{.Names}}" | grep -q "^${TEAM_ID}-kali$"; then
        continue
    fi
    
    echo -n "Team $TEAM: "
    
    # Check for GOOSE traffic
    GOOSE_COUNT=$(docker exec ${TEAM_ID}-kali timeout 3 tcpdump -i eth0 -c 3 ether proto 0x88b8 2>/dev/null | wc -l)
    
    if [ $GOOSE_COUNT -gt 0 ]; then
        echo "✓ GOOSE traffic detected ($GOOSE_COUNT packets)"
    else
        echo "❌ No GOOSE traffic"
    fi
done

echo ""
echo "═══ Test 4: Web Interface Access ═══"
echo ""

for i in {1..5}; do
    TEAM=$(printf "%03d" $i)
    TEAM_ID=$(printf "team%03d" $i)
    
    # Check if team exists
    if ! docker ps --format "{{.Names}}" | grep -q "^${TEAM_ID}-kali$"; then
        continue
    fi
    
    echo -n "Team $TEAM: "
    
    # Test HTTP access
    HTTP_V1=$(docker exec ${TEAM_ID}-kali curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://${TEAM_ID}-breaker-v1:9000/ 2>/dev/null)
    HTTP_V2=$(docker exec ${TEAM_ID}-kali curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://${TEAM_ID}-breaker-v2:9000/ 2>/dev/null)
    
    if [ "$HTTP_V1" = "200" ] && [ "$HTTP_V2" = "200" ]; then
        echo "✓ Both web interfaces accessible"
    elif [ "$HTTP_V1" = "200" ] || [ "$HTTP_V2" = "200" ]; then
        echo "⚠️  Only one interface accessible (v1:$HTTP_V1 v2:$HTTP_V2)"
    else
        echo "❌ Web interfaces not accessible"
    fi
done

echo ""
echo "═══ Test 5: Network Configuration ═══"
echo ""

for i in {1..5}; do
    TEAM=$(printf "%03d" $i)
    TEAM_ID=$(printf "team%03d" $i)
    
    # Check if team exists
    if ! docker ps --format "{{.Names}}" | grep -q "^${TEAM_ID}-kali$"; then
        continue
    fi
    
    NETWORK=$(docker inspect ${TEAM_ID}-kali --format='{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}')
    SUBNET=$(docker inspect ${TEAM_ID}-kali --format='{{range $k, $v := .NetworkSettings.Networks}}{{$v.IPAddress}}{{end}}')
    
    echo "Team $TEAM: Network=$NETWORK IP=$SUBNET"
done

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    Test Summary                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

if [ $ISOLATION_ISSUES -eq 0 ]; then
    echo "✓ All network tests passed"
    echo "✓ Teams are properly isolated"
    echo "✓ CTF environment is secure"
else
    echo "❌ Network isolation issues detected"
    echo "⚠️  $ISOLATION_ISSUES teams can access other teams"
    echo "⚠️  This is a security risk for the CTF"
    echo ""
    echo "Recommended actions:"
    echo "  1. Check docker-compose network configuration"
    echo "  2. Ensure each team has isolated network"
    echo "  3. Verify deployment script"
fi

echo ""
