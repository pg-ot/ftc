#!/bin/bash
# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# Test network isolation between teams

if [ -z "$1" ]; then
    SOURCE_TEAM="001"
else
    SOURCE_TEAM=$1
fi

if [ -z "$2" ]; then
    TARGET_TEAM="002"
else
    TARGET_TEAM=$2
fi

SOURCE_TEAM_ID=$(printf "team%03d" $SOURCE_TEAM)
TARGET_TEAM_ID=$(printf "team%03d" $TARGET_TEAM)

echo "=== Network Isolation Test ==="
echo "Time: $(date)"
echo ""
echo "Source: Team $SOURCE_TEAM"
echo "Target: Team $TARGET_TEAM"
echo ""

# Check if source Kali exists
if ! docker ps --format "{{.Names}}" | grep -q "^${SOURCE_TEAM_ID}-kali$"; then
    echo "❌ Source team Kali container not found: ${SOURCE_TEAM_ID}-kali"
    exit 1
fi

# Check if target containers exist
if ! docker ps --format "{{.Names}}" | grep -q "^${TARGET_TEAM_ID}-breaker-v1$"; then
    echo "❌ Target team containers not found: ${TARGET_TEAM_ID}"
    exit 1
fi

echo "Testing isolation (Team $SOURCE_TEAM → Team $TARGET_TEAM)..."
echo ""

# Test 1: Ping target breaker-v1
echo "1. Ping ${TARGET_TEAM_ID}-breaker-v1:"
if docker exec ${SOURCE_TEAM_ID}-kali ping -c 2 -W 2 ${TARGET_TEAM_ID}-breaker-v1 2>/dev/null >/dev/null; then
    echo "   ❌ FAILED - Can reach other team's container!"
    ISOLATION_BROKEN=1
else
    echo "   ✓ PASS - Cannot reach (isolated)"
fi

# Test 2: Ping target breaker-v2
echo ""
echo "2. Ping ${TARGET_TEAM_ID}-breaker-v2:"
if docker exec ${SOURCE_TEAM_ID}-kali ping -c 2 -W 2 ${TARGET_TEAM_ID}-breaker-v2 2>/dev/null >/dev/null; then
    echo "   ❌ FAILED - Can reach other team's container!"
    ISOLATION_BROKEN=1
else
    echo "   ✓ PASS - Cannot reach (isolated)"
fi

# Test 3: Ping target control
echo ""
echo "3. Ping ${TARGET_TEAM_ID}-control:"
if docker exec ${SOURCE_TEAM_ID}-kali ping -c 2 -W 2 ${TARGET_TEAM_ID}-control 2>/dev/null >/dev/null; then
    echo "   ❌ FAILED - Can reach other team's container!"
    ISOLATION_BROKEN=1
else
    echo "   ✓ PASS - Cannot reach (isolated)"
fi

# Test 4: Ping target Kali
echo ""
echo "4. Ping ${TARGET_TEAM_ID}-kali:"
if docker exec ${SOURCE_TEAM_ID}-kali ping -c 2 -W 2 ${TARGET_TEAM_ID}-kali 2>/dev/null >/dev/null; then
    echo "   ❌ FAILED - Can reach other team's container!"
    ISOLATION_BROKEN=1
else
    echo "   ✓ PASS - Cannot reach (isolated)"
fi

# Test 5: HTTP access to target breaker
echo ""
echo "5. HTTP access to ${TARGET_TEAM_ID}-breaker-v1:"
HTTP_CODE=$(docker exec ${SOURCE_TEAM_ID}-kali curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://${TARGET_TEAM_ID}-breaker-v1:9000/ 2>/dev/null)
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "000" ]; then
    if [ "$HTTP_CODE" = "200" ]; then
        echo "   ❌ FAILED - Can access other team's web interface!"
        ISOLATION_BROKEN=1
    else
        echo "   ✓ PASS - Cannot access (isolated)"
    fi
else
    echo "   ✓ PASS - Cannot access (isolated)"
fi

# Test 6: Check network namespaces
echo ""
echo "6. Network namespace check:"
SOURCE_NET=$(docker inspect ${SOURCE_TEAM_ID}-kali --format='{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}')
TARGET_NET=$(docker inspect ${TARGET_TEAM_ID}-breaker-v1 --format='{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}')

if [ "$SOURCE_NET" = "$TARGET_NET" ]; then
    echo "   ❌ FAILED - Teams on same network: $SOURCE_NET"
    ISOLATION_BROKEN=1
else
    echo "   ✓ PASS - Different networks"
    echo "      Source: $SOURCE_NET"
    echo "      Target: $TARGET_NET"
fi

echo ""
echo "═══════════════════════════════════════"

if [ -n "$ISOLATION_BROKEN" ]; then
    echo "❌ ISOLATION TEST FAILED"
    echo ""
    echo "⚠️  WARNING: Teams can access each other!"
    echo "This is a security issue for the CTF."
    echo ""
    echo "Recommended fixes:"
    echo "  1. Ensure each team has isolated Docker network"
    echo "  2. Check docker-compose network configuration"
    echo "  3. Verify firewall rules"
    exit 1
else
    echo "✓ ISOLATION TEST PASSED"
    echo ""
    echo "Teams are properly isolated."
fi
