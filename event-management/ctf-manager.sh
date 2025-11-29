#!/bin/bash
# Interactive CTF Management Tool

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display header
show_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         IEC 61850 GOOSE CTF - Management Console              ║${NC}"
    echo -e "${CYAN}║         $(date '+%Y-%m-%d %H:%M:%S')                                    ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to select team
select_team() {
    # Get deployed teams
    DEPLOYED_TEAMS=($(docker ps --filter "name=team" --format "{{.Names}}" | grep -o "team[0-9]\+" | sort -u))
    
    if [ ${#DEPLOYED_TEAMS[@]} -eq 0 ]; then
        echo -e "${RED}No teams deployed${NC}"
        sleep 2
        return 1
    fi
    
    echo -e "${YELLOW}Select Team:${NC}"
    
    # Show deployed teams dynamically
    for i in "${!DEPLOYED_TEAMS[@]}"; do
        TEAM_NUM=$(echo "${DEPLOYED_TEAMS[$i]}" | grep -o "[0-9]\+")
        echo "  $((i+1))) Team $TEAM_NUM"
    done
    
    echo "  a) All Teams"
    echo "  b) Back"
    echo ""
    read -p "Choice: " team_choice
    
    if [[ $team_choice =~ ^[0-9]+$ ]] && [ $team_choice -ge 1 ] && [ $team_choice -le ${#DEPLOYED_TEAMS[@]} ]; then
        TEAM=$(echo "${DEPLOYED_TEAMS[$((team_choice-1))]}" | grep -o "[0-9]\+")
        return 0
    elif [[ $team_choice =~ ^[Aa]$ ]]; then
        TEAM="ALL"
        return 0
    elif [[ $team_choice =~ ^[Bb]$ ]]; then
        return 1
    else
        echo -e "${RED}Invalid choice${NC}"
        sleep 1
        return 1
    fi
}

# Function to select component
select_component() {
    echo -e "${YELLOW}Select Component:${NC}"
    echo "  1) Breaker v1"
    echo "  2) Breaker v2"
    echo "  3) Control IED"
    echo "  4) Kali Workstation"
    echo "  5) All Components"
    echo "  b) Back"
    echo ""
    read -p "Choice: " comp_choice
    
    case $comp_choice in
        1) COMPONENT="breaker-v1" ;;
        2) COMPONENT="breaker-v2" ;;
        3) COMPONENT="control" ;;
        4) COMPONENT="kali" ;;
        5) COMPONENT="ALL" ;;
        b|B) return 1 ;;
        *) echo -e "${RED}Invalid choice${NC}"; sleep 1; return 1 ;;
    esac
    return 0
}

# Function to show status
show_status() {
    show_header
    
    if select_team; then
        echo ""
        if [ "$TEAM" = "ALL" ]; then
            "$SCRIPT_DIR/status.sh"
        else
            "$SCRIPT_DIR/status.sh" team$(printf "%03d" $TEAM)
        fi
        echo ""
        read -p "Press Enter to continue..."
    fi
}

# Function to restart containers
restart_containers() {
    show_header
    
    if select_team; then
        echo ""
        if [ "$TEAM" = "ALL" ]; then
            echo -e "${YELLOW}Restarting ALL teams...${NC}"
            "$SCRIPT_DIR/restart-all.sh"
        else
            if select_component; then
                echo ""
                TEAM_ID=$(printf "team%03d" $TEAM)
                
                if [ "$COMPONENT" = "ALL" ]; then
                    echo -e "${YELLOW}Restarting all containers for Team $TEAM...${NC}"
                    "$SCRIPT_DIR/restart-team.sh" $TEAM
                else
                    echo -e "${YELLOW}Restarting ${TEAM_ID}-${COMPONENT}...${NC}"
                    docker restart ${TEAM_ID}-${COMPONENT}
                    echo -e "${GREEN}✓ Restarted${NC}"
                fi
            fi
        fi
        echo ""
        read -p "Press Enter to continue..."
    fi
}

# Function to view logs
view_logs() {
    show_header
    
    if select_team; then
        if [ "$TEAM" = "ALL" ]; then
            if select_component; then
                echo ""
                # Get all deployed teams dynamically
                DEPLOYED_TEAMS=($(docker ps --filter "name=team" --format "{{.Names}}" | grep -o "team[0-9]\+" | sort -u))
                for TEAM_ID in "${DEPLOYED_TEAMS[@]}"; do
                    if [ "$COMPONENT" = "ALL" ]; then
                        echo -e "${CYAN}=== $TEAM_ID ===${NC}"
                        docker ps --filter "name=$TEAM_ID" --format "{{.Names}}: {{.Status}}"
                    else
                        echo -e "${CYAN}=== ${TEAM_ID}-${COMPONENT} ===${NC}"
                        docker logs --tail=20 ${TEAM_ID}-${COMPONENT} 2>/dev/null || echo "Not found"
                    fi
                    echo ""
                done
                read -p "Press Enter to continue..."
            fi
            return
        fi
        
        TEAM_ID=$(printf "team%03d" $TEAM)
        
        if select_component; then
            echo ""
            if [ "$COMPONENT" = "ALL" ]; then
                "$SCRIPT_DIR/logs.sh" $TEAM_ID
            else
                echo -e "${YELLOW}Viewing logs for ${TEAM_ID}-${COMPONENT}${NC}"
                echo -e "${CYAN}Press Ctrl+C to exit${NC}"
                echo ""
                sleep 2
                docker logs -f --tail=50 ${TEAM_ID}-${COMPONENT}
            fi
            echo ""
            read -p "Press Enter to continue..."
        fi
    fi
}

# Function to check network
check_network() {
    show_header
    
    if select_team; then
        echo ""
        "$SCRIPT_DIR/network-check.sh" $TEAM
        echo ""
        read -p "Press Enter to continue..."
    fi
}

# Function to reset team
reset_team() {
    show_header
    
    if select_team; then
        echo ""
        echo -e "${RED}⚠️  WARNING: This will fully reset Team $TEAM${NC}"
        read -p "Are you sure? (y/n): " confirm
        
        if [[ $confirm =~ ^[Yy]$ ]]; then
            "$SCRIPT_DIR/reset-team.sh" $TEAM
        else
            echo "Cancelled"
        fi
        echo ""
        read -p "Press Enter to continue..."
    fi
}

# Function to check flags
check_flags() {
    show_header
    
    if select_team; then
        echo ""
        if [ "$TEAM" = "ALL" ]; then
            "$SCRIPT_DIR/check-flags.sh"
        else
            "$SCRIPT_DIR/check-flags.sh" $TEAM
        fi
        echo ""
        read -p "Press Enter to continue..."
    fi
}

# Function to test network isolation
test_isolation() {
    show_header
    
    echo -e "${YELLOW}Network Isolation Test${NC}"
    echo ""
    echo "  1) Test All Teams (Comprehensive)"
    echo "  2) Test Specific Teams"
    echo "  b) Back"
    echo ""
    read -p "Choice: " test_choice
    
    case $test_choice in
        1)
            echo ""
            "$SCRIPT_DIR/test-all-networks.sh"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        2)
            echo ""
            read -p "Source team (001-005): " source
            read -p "Target team (001-005): " target
            
            if [ -z "$source" ] || [ -z "$target" ]; then
                echo -e "${RED}Invalid input${NC}"
                sleep 2
                return
            fi
            
            echo ""
            "$SCRIPT_DIR/network-isolation-test.sh" $source $target
            echo ""
            read -p "Press Enter to continue..."
            ;;
        b|B)
            return
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            sleep 1
            ;;
    esac
}

# Function to access container shell
access_shell() {
    show_header
    
    if select_team; then
        TEAM_ID=$(printf "team%03d" $TEAM)
        
        if select_component; then
            echo ""
            CONTAINER="${TEAM_ID}-${COMPONENT}"
            
            if docker ps --format "{{.Names}}" | grep -q "^${CONTAINER}$"; then
                echo -e "${GREEN}Accessing ${CONTAINER}...${NC}"
                echo -e "${CYAN}Type 'exit' to return to menu${NC}"
                echo ""
                sleep 1
                docker exec -it $CONTAINER /bin/bash || docker exec -it $CONTAINER /bin/sh
            else
                echo -e "${RED}Container ${CONTAINER} not found or not running${NC}"
                sleep 2
            fi
        fi
    fi
}

# Function to show quick stats
show_quick_stats() {
    TOTAL=$(docker ps -a --filter "name=team" -q | wc -l)
    RUNNING=$(docker ps --filter "name=team" -q | wc -l)
    STOPPED=$((TOTAL - RUNNING))
    
    echo -e "${CYAN}Quick Stats:${NC}"
    echo -e "  Running: ${GREEN}$RUNNING${NC} / $TOTAL"
    if [ $STOPPED -gt 0 ]; then
        echo -e "  Stopped: ${RED}$STOPPED${NC}"
    fi
    echo ""
}

# Main menu
main_menu() {
    while true; do
        show_header
        show_quick_stats
        
        echo -e "${YELLOW}Main Menu:${NC}"
        echo "  1) Show Status"
        echo "  2) Restart Containers"
        echo "  3) View Logs"
        echo "  4) Check Network"
        echo "  5) Test Network Isolation"
        echo "  6) Check Flags"
        echo "  7) Reset Team"
        echo "  8) Access Container Shell"
        echo "  9) Live Monitor"
        echo "  a) Create Backup"
        echo "  0) Emergency Stop All"
        echo "  q) Quit"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) show_status ;;
            2) restart_containers ;;
            3) view_logs ;;
            4) check_network ;;
            5) test_isolation ;;
            6) check_flags ;;
            7) reset_team ;;
            8) access_shell ;;
            9) 
                clear
                echo -e "${CYAN}Starting live monitor... Press Ctrl+C to return${NC}"
                sleep 2
                "$SCRIPT_DIR/monitor.sh"
                ;;
            a|A)
                show_header
                echo -e "${YELLOW}Creating backup...${NC}"
                "$SCRIPT_DIR/backup.sh"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            0)
                show_header
                echo -e "${RED}⚠️  EMERGENCY STOP${NC}"
                "$SCRIPT_DIR/emergency-stop.sh"
                echo "
"
                read -p "Press Enter to continue..."
                ;;
            q|Q)
                clear
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                sleep 1
                ;;
        esac
    done
}

# Start the application
main_menu
