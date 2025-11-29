#!/bin/bash
# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# Real-time monitoring dashboard

# Trap Ctrl+C to exit gracefully
trap 'echo ""; echo "Exiting monitor..."; exit 0' INT

while true; do
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         IEC 61850 GOOSE CTF - Live Monitor                    ║"
    echo "║         $(date '+%Y-%m-%d %H:%M:%S')                                    ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Container status
    TOTAL=$(docker ps -a --filter "name=team" -q | wc -l)
    RUNNING=$(docker ps --filter "name=team" -q | wc -l)
    STOPPED=$((TOTAL - RUNNING))
    
    # SCADA status
    SCADA_TOTAL=$(docker ps -a --filter "name=openplc" -q | wc -l)
    SCADA_TOTAL=$((SCADA_TOTAL + $(docker ps -a --filter "name=scadabr" -q | wc -l)))
    SCADA_RUNNING=$(docker ps --filter "name=openplc" -q | wc -l)
    SCADA_RUNNING=$((SCADA_RUNNING + $(docker ps --filter "name=scadabr" -q | wc -l)))
    
    echo "📊 Container Status:"
    echo "   Teams: $RUNNING / $TOTAL"
    echo "   SCADA: $SCADA_RUNNING / $SCADA_TOTAL (OpenPLC + ScadaBR)"
    if [ $STOPPED -gt 0 ]; then
        echo "   ⚠️  Stopped: $STOPPED"
    fi
    echo ""
    
    # System resources
    echo "💻 System Resources:"
    echo "   CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')% used"
    echo "   Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo "   Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
    
    # Network stats
    NET_RX=$(cat /sys/class/net/eth0/statistics/rx_bytes 2>/dev/null || echo 0)
    NET_TX=$(cat /sys/class/net/eth0/statistics/tx_bytes 2>/dev/null || echo 0)
    NET_RX_MB=$(echo "scale=2; $NET_RX / 1024 / 1024" | bc 2>/dev/null || echo "0")
    NET_TX_MB=$(echo "scale=2; $NET_TX / 1024 / 1024" | bc 2>/dev/null || echo "0")
    echo "   Network: ↓${NET_RX_MB}MB ↑${NET_TX_MB}MB (total)"
    echo ""
    
    # Team status summary
    echo "👥 Team Status:"
    ACTIVE_TEAMS=0
    for i in {1..5}; do
        TEAM_ID=$(printf "team%03d" $i)
        COUNT=$(docker ps --filter "name=$TEAM_ID" -q | wc -l)
        TOTAL_TEAM=$(docker ps -a --filter "name=$TEAM_ID" -q | wc -l)
        
        if [ $COUNT -eq $TOTAL_TEAM ] && [ $COUNT -gt 0 ]; then
            STATUS="✓"
            ACTIVE_TEAMS=$((ACTIVE_TEAMS + 1))
        elif [ $COUNT -eq 0 ]; then
            STATUS="✗"
        else
            STATUS="⚠"
        fi
        
        echo "   $STATUS Team $i: $COUNT/$TOTAL_TEAM containers"
    done
    
    echo ""
    echo "🌐 Network Activity:"
    GOOSE_TOTAL=0
    for i in {1..5}; do
        TEAM_ID=$(printf "team%03d" $i)
        if docker ps --format "{{.Names}}" | grep -q "^${TEAM_ID}-kali$"; then
            GOOSE=$(docker exec ${TEAM_ID}-kali timeout 2 tcpdump -i eth0 -c 10 ether proto 0x88b8 2>/dev/null | wc -l)
            GOOSE_TOTAL=$((GOOSE_TOTAL + GOOSE))
            if [ $GOOSE -gt 0 ]; then
                echo "   Team $i: ${GOOSE} GOOSE packets/2s"
            fi
        fi
    done
    if [ $GOOSE_TOTAL -eq 0 ]; then
        echo "   No GOOSE traffic detected"
    fi
    
    echo ""
    echo "📈 Capacity Analytics:"
    
    # Calculate per-team resource usage
    if [ $ACTIVE_TEAMS -gt 0 ]; then
        TOTAL_MEM=$(free -m | awk '/^Mem:/ {print $2}')
        USED_MEM=$(free -m | awk '/^Mem:/ {print $3}')
        CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        
        PER_TEAM_MEM=$((USED_MEM / ACTIVE_TEAMS))
        PER_TEAM_CPU=$(echo "scale=1; $CPU_USAGE / $ACTIVE_TEAMS" | bc 2>/dev/null || echo "N/A")
        
        # Estimate max teams (80% capacity)
        MAX_BY_MEM=$((TOTAL_MEM * 80 / 100 / PER_TEAM_MEM))
        MAX_BY_CPU=$(echo "scale=0; 80 / $PER_TEAM_CPU" | bc 2>/dev/null || echo "N/A")
        
        echo "   Per Team: ${PER_TEAM_MEM}Mi RAM, ${PER_TEAM_CPU}% CPU"
        echo "   Max Teams: $MAX_BY_MEM (RAM limit), $MAX_BY_CPU (CPU limit)"
        echo "   Network: Not a bottleneck (GOOSE ~84 bytes/sec per team)"
        
        if [ "$MAX_BY_CPU" != "N/A" ] && [ $MAX_BY_CPU -lt $MAX_BY_MEM ]; then
            echo "   ⚠️  CPU is the bottleneck (recommend: $MAX_BY_CPU teams max)"
        else
            echo "   ✓ Can support up to $MAX_BY_MEM teams on this VM"
        fi
    else
        echo "   No active teams to calculate capacity"
    fi
    
    echo ""
    echo "🔄 Refreshing in 5 seconds... (Press Ctrl+C to exit)"
    
    sleep 5
done
