#!/bin/bash
# Health check for all CTF services

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         CTF Environment Health Check                          ║"
echo "║         $(date '+%Y-%m-%d %H:%M:%S')                                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

ISSUES=0

# Check Docker
if ! docker ps &>/dev/null; then
    echo "✗ Docker is not running"
    ISSUES=$((ISSUES + 1))
else
    echo "✓ Docker is running"
fi

# Check deployed teams
TEAMS=($(docker ps --filter "name=team" --format "{{.Names}}" | grep -o "team[0-9]\+" | sort -u))
if [ ${#TEAMS[@]} -eq 0 ]; then
    echo "✗ No teams deployed"
    ISSUES=$((ISSUES + 1))
else
    echo "✓ ${#TEAMS[@]} team(s) deployed"
fi

echo ""
echo "Team Health:"
for team in "${TEAMS[@]}"; do
    echo "  $team:"
    
    # Check containers
    EXPECTED=6  # breaker-v1, breaker-v2, control, kali, openplc, scadabr
    RUNNING=$(docker ps --filter "name=$team" -q | wc -l)
    
    if [ $RUNNING -eq $EXPECTED ]; then
        echo "    ✓ All containers running ($RUNNING/$EXPECTED)"
    else
        echo "    ✗ Missing containers ($RUNNING/$EXPECTED)"
        ISSUES=$((ISSUES + 1))
    fi
    
    # Check SSH
    TEAM_NUM=$(echo "$team" | grep -o "[0-9]\+")
    SSH_PORT=$((20000 + TEAM_NUM))
    if nc -z localhost $SSH_PORT 2>/dev/null; then
        echo "    ✓ SSH accessible (port $SSH_PORT)"
    else
        echo "    ✗ SSH not accessible (port $SSH_PORT)"
        ISSUES=$((ISSUES + 1))
    fi
    
    # Check web services
    BREAKER_PORT=$((9001 + (TEAM_NUM - 1) * 10))
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$BREAKER_PORT 2>/dev/null | grep -q "200"; then
        echo "    ✓ Breaker web accessible"
    else
        echo "    ✗ Breaker web not accessible"
        ISSUES=$((ISSUES + 1))
    fi
    
    # Check GOOSE traffic
    GOOSE=$(docker exec ${team}-kali timeout 2 tcpdump -i eth0 -c 5 ether proto 0x88b8 2>/dev/null | wc -l)
    if [ $GOOSE -gt 0 ]; then
        echo "    ✓ GOOSE traffic detected"
    else
        echo "    ✗ No GOOSE traffic"
        ISSUES=$((ISSUES + 1))
    fi
done

echo ""
echo "System Resources:"
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
MEM_USED=$(free -m | awk '/^Mem:/ {print $3}')
MEM_TOTAL=$(free -m | awk '/^Mem:/ {print $2}')
MEM_PERCENT=$(echo "scale=1; $MEM_USED * 100 / $MEM_TOTAL" | bc)
DISK_PERCENT=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)

echo "  CPU Usage: ${CPU}%"
if (( $(echo "$CPU > 80" | bc -l) )); then
    echo "    ⚠️  High CPU usage"
    ISSUES=$((ISSUES + 1))
fi

echo "  Memory: ${MEM_USED}MB / ${MEM_TOTAL}MB (${MEM_PERCENT}%)"
if (( $(echo "$MEM_PERCENT > 85" | bc -l) )); then
    echo "    ⚠️  High memory usage"
    ISSUES=$((ISSUES + 1))
fi

echo "  Disk: ${DISK_PERCENT}% used"
if [ $DISK_PERCENT -gt 85 ]; then
    echo "    ⚠️  Low disk space"
    ISSUES=$((ISSUES + 1))
fi

echo ""
if [ $ISSUES -eq 0 ]; then
    echo "✓ All checks passed - System healthy"
    exit 0
else
    echo "✗ Found $ISSUES issue(s) - Review required"
    exit 1
fi
