#!/bin/bash
# Comprehensive CTF Administration Tool
# Handles installation, deployment, updates, and management

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/pg-ot/ftc.git"
INSTALL_DIR="$HOME/ftc"
COMPOSE_FILE="deployment/docker-compose-ctf-final.yml"

# Function to display header
show_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         IEC 61850 GOOSE CTF - Admin Console                   ║${NC}"
    echo -e "${CYAN}║         $(date '+%Y-%m-%d %H:%M:%S')                                    ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to check if in repo directory
check_repo() {
    # Check current directory
    if [ -d ".git" ]; then
        return 0
    fi
    
    # Check parent directory (if running from event-management)
    if [ -d "../.git" ]; then
        cd ..
        return 0
    fi
    
    echo -e "${RED}❌ Not in a Git repository!${NC}"
    echo -e "${YELLOW}Please run this from the ftc directory or use Installation menu${NC}"
    return 1
}

# Function to show quick stats
show_quick_stats() {
    if docker ps &>/dev/null; then
        TOTAL=$(docker ps -a --filter "name=team" -q 2>/dev/null | wc -l)
        RUNNING=$(docker ps --filter "name=team" -q 2>/dev/null | wc -l)
        
        echo -e "${CYAN}Quick Stats:${NC}"
        if [ $TOTAL -gt 0 ]; then
            echo -e "  Running: ${GREEN}$RUNNING${NC} / $TOTAL containers"
            if [ $RUNNING -ne $TOTAL ]; then
                echo -e "  ${RED}⚠️  $((TOTAL - RUNNING)) containers stopped${NC}"
            fi
        else
            echo -e "  ${YELLOW}No CTF containers deployed${NC}"
        fi
        echo ""
    fi
}

# ============================================================================
# INSTALLATION MENU
# ============================================================================

install_menu() {
    while true; do
        show_header
        echo -e "${MAGENTA}═══ Installation & Setup ═══${NC}"
        echo ""
        echo "  1) Fresh Installation (Clone repo)"
        echo "  2) Install Dependencies"
        echo "  3) Initialize Git Submodules"
        echo "  4) Build Docker Images"
        echo "  5) Rebuild Images (No Cache)"
        echo "  6) Complete Setup (All of above)"
        echo "  b) Back to Main Menu"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) fresh_install ;;
            2) install_dependencies ;;
            3) init_submodules ;;
            4) build_images ;;
            5) rebuild_no_cache ;;
            6) complete_setup ;;
            b|B) return ;;
            *) echo -e "${RED}Invalid choice${NC}"; sleep 1 ;;
        esac
    done
}

fresh_install() {
    show_header
    echo -e "${YELLOW}Fresh Installation${NC}"
    echo ""
    
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}Directory $INSTALL_DIR already exists!${NC}"
        read -p "Remove and reinstall? (y/n): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            cd ~
            rm -rf "$INSTALL_DIR"
        else
            echo "Cancelled"
            sleep 2
            return
        fi
    fi
    
    echo "Cloning repository with submodules..."
    git clone --recurse-submodules "$REPO_URL" "$INSTALL_DIR"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Repository cloned successfully${NC}"
        echo ""
        echo "Next steps:"
        echo "  cd $INSTALL_DIR/event-management"
        echo "  ./ctf-admin.sh"
    else
        echo -e "${RED}✗ Clone failed${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

install_dependencies() {
    show_header
    echo -e "${YELLOW}Installing Dependencies${NC}"
    echo ""
    
    echo "Checking system..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker not found. Installing...${NC}"
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        echo -e "${GREEN}✓ Docker installed${NC}"
    else
        echo -e "${GREEN}✓ Docker already installed${NC}"
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${YELLOW}Docker Compose not found. Installing...${NC}"
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo -e "${GREEN}✓ Docker Compose installed${NC}"
    else
        echo -e "${GREEN}✓ Docker Compose already installed${NC}"
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}Git not found. Installing...${NC}"
        sudo apt-get update && sudo apt-get install -y git
        echo -e "${GREEN}✓ Git installed${NC}"
    else
        echo -e "${GREEN}✓ Git already installed${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}✓ All dependencies installed${NC}"
    read -p "Press Enter to continue..."
}

init_submodules() {
    show_header
    echo -e "${YELLOW}Initializing Git Submodules${NC}"
    echo ""
    
    if ! check_repo; then
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "Checking submodules..."
    git submodule status
    
    echo ""
    echo "Initializing submodules..."
    git submodule update --init --recursive
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Submodules initialized${NC}"
    else
        echo -e "${RED}✗ Submodule initialization failed${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

build_images() {
    show_header
    echo -e "${YELLOW}Building Docker Images${NC}"
    echo ""
    
    if ! check_repo; then
        read -p "Press Enter to continue..."
        return
    fi
    
    cd deployment 2>/dev/null || {
        echo -e "${RED}✗ deployment directory not found${NC}"
        read -p "Press Enter to continue..."
        return
    }
    
    echo "Building images (this may take several minutes)..."
    docker-compose -f docker-compose-ctf-final.yml build
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ Images built successfully${NC}"
    else
        echo -e "${RED}✗ Build failed${NC}"
    fi
    
    cd ..
    read -p "Press Enter to continue..."
}

rebuild_no_cache() {
    show_header
    echo -e "${YELLOW}Rebuild Images (No Cache)${NC}"
    echo ""
    echo -e "${YELLOW}This will rebuild all images from scratch (no cache)${NC}"
    echo -e "${YELLOW}Use this when Dockerfile changes aren't being applied${NC}"
    echo ""
    
    if ! check_repo; then
        read -p "Press Enter to continue..."
        return
    fi
    
    read -p "Continue? (y/n): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        return
    fi
    
    cd deployment 2>/dev/null || {
        echo -e "${RED}✗ deployment directory not found${NC}"
        read -p "Press Enter to continue..."
        return
    }
    
    echo ""
    echo "Rebuilding images without cache (this will take longer)..."
    docker-compose -f docker-compose-ctf-final.yml build --no-cache
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ Images rebuilt successfully${NC}"
    else
        echo -e "${RED}✗ Build failed${NC}"
    fi
    
    cd ..
    read -p "Press Enter to continue..."
}

complete_setup() {
    show_header
    echo -e "${YELLOW}Complete Setup${NC}"
    echo ""
    echo "This will:"
    echo "  1. Install dependencies"
    echo "  2. Initialize submodules"
    echo "  3. Build Docker images"
    echo ""
    read -p "Continue? (y/n): " confirm
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        return
    fi
    
    install_dependencies
    init_submodules
    build_images
    
    echo ""
    echo -e "${GREEN}✓ Complete setup finished!${NC}"
    read -p "Press Enter to continue..."
}

# ============================================================================
# DEPLOYMENT MENU
# ============================================================================

deployment_menu() {
    while true; do
        show_header
        echo -e "${MAGENTA}═══ Deployment ═══${NC}"
        echo ""
        echo "  1) Deploy CTF Environment"
        echo "  2) Deploy Specific Number of Teams"
        echo "  3) Change Team Passwords"
        echo "  4) Stop All Containers"
        echo "  5) Start All Containers"
        echo "  6) Remove All Containers"
        echo "  7) Full Cleanup (Containers + Images)"
        echo "  b) Back to Main Menu"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) deploy_ctf ;;
            2) deploy_teams ;;
            3) change_passwords ;;
            4) stop_all ;;
            5) start_all ;;
            6) remove_all ;;
            7) full_cleanup ;;
            b|B) return ;;
            *) echo -e "${RED}Invalid choice${NC}"; sleep 1 ;;
        esac
    done
}

deploy_ctf() {
    show_header
    echo -e "${YELLOW}Deploy CTF Environment${NC}"
    echo ""
    
    if ! check_repo; then
        read -p "Press Enter to continue..."
        return
    fi
    
    cd deployment 2>/dev/null || {
        echo -e "${RED}✗ deployment directory not found${NC}"
        read -p "Press Enter to continue..."
        return
    }
    
    echo "Starting CTF environment..."
    docker-compose -f docker-compose-ctf-final.yml up -d
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ CTF environment deployed${NC}"
        echo ""
        echo "Access URLs:"
        echo "  Breaker v1: http://localhost:9001"
        echo "  Breaker v2: http://localhost:9002"
        echo "  OpenPLC:    http://localhost:8081 (openplc/openplc)"
        echo "  ScadaBR:    http://localhost:8080/ScadaBR (admin/admin)"
        echo "  Modbus TCP: localhost:502"
    else
        echo -e "${RED}✗ Deployment failed${NC}"
    fi
    
    cd ..
    read -p "Press Enter to continue..."
}

deploy_teams() {
    show_header
    echo -e "${YELLOW}Deploy Multiple Teams${NC}"
    echo ""
    
    read -p "Number of teams to deploy: " num_teams
    
    if ! [[ "$num_teams" =~ ^[0-9]+$ ]] || [ "$num_teams" -lt 1 ]; then
        echo -e "${RED}Invalid number${NC}"
        sleep 2
        return
    fi
    
    echo ""
    echo "Deploying $num_teams teams..."
    
    # Find deployment directory
    DEPLOY_DIR=""
    if [ -d "deployment" ]; then
        DEPLOY_DIR="deployment"
    elif [ -d "../deployment" ]; then
        DEPLOY_DIR="../deployment"
    else
        echo -e "${RED}✗ deployment directory not found${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    SCRIPT_PATH="$DEPLOY_DIR/deploy-cloud-hardened.sh"
    
    if [ -f "$SCRIPT_PATH" ]; then
        bash "$SCRIPT_PATH" $num_teams
        if [ $? -eq 0 ]; then
            echo ""
            echo -e "${GREEN}✓ $num_teams team(s) deployed successfully${NC}"
        else
            echo -e "${RED}✗ Deployment failed${NC}"
        fi
    else
        echo -e "${RED}✗ deploy-cloud-hardened.sh not found at $SCRIPT_PATH${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

change_passwords() {
    show_header
    echo -e "${YELLOW}Change Team Passwords${NC}"
    echo ""
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    if [ -f "$SCRIPT_DIR/change-team-passwords.sh" ]; then
        bash "$SCRIPT_DIR/change-team-passwords.sh"
    else
        echo -e "${RED}✗ change-team-passwords.sh not found${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

stop_all() {
    show_header
    echo -e "${YELLOW}Stop All Containers${NC}"
    echo ""
    
    read -p "Stop all CTF containers? (y/n): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        return
    fi
    
    echo "Stopping containers..."
    docker stop $(docker ps --filter "name=team" -q) 2>/dev/null
    docker stop $(docker ps --filter "name=substation" -q) 2>/dev/null
    docker stop openplc scadabr kali-workstation 2>/dev/null
    
    echo -e "${GREEN}✓ All containers stopped${NC}"
    read -p "Press Enter to continue..."
}

start_all() {
    show_header
    echo -e "${YELLOW}Start All Containers${NC}"
    echo ""
    
    echo "Starting containers..."
    docker start openplc scadabr 2>/dev/null
    sleep 2
    docker start $(docker ps -a --filter "name=substation" -q) 2>/dev/null
    docker start kali-workstation 2>/dev/null
    docker start $(docker ps -a --filter "name=team" -q) 2>/dev/null
    
    echo -e "${GREEN}✓ All containers started${NC}"
    read -p "Press Enter to continue..."
}

remove_all() {
    show_header
    echo -e "${YELLOW}Remove All Containers${NC}"
    echo ""
    
    read -p "Remove all CTF containers? (y/n): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        return
    fi
    
    echo "Stopping and removing containers..."
    docker stop $(docker ps -a --filter "name=team" -q) 2>/dev/null
    docker rm $(docker ps -a --filter "name=team" -q) 2>/dev/null
    docker stop $(docker ps -a --filter "name=substation" -q) 2>/dev/null
    docker rm $(docker ps -a --filter "name=substation" -q) 2>/dev/null
    docker stop openplc scadabr kali-workstation 2>/dev/null
    docker rm openplc scadabr kali-workstation 2>/dev/null
    
    echo -e "${GREEN}✓ All containers removed${NC}"
    read -p "Press Enter to continue..."
}

full_cleanup() {
    show_header
    echo -e "${RED}Full Cleanup${NC}"
    echo ""
    echo -e "${RED}⚠️  WARNING: This will remove:${NC}"
    echo "  - All CTF containers"
    echo "  - All CTF Docker images"
    echo "  - All CTF networks"
    echo ""
    read -p "Are you sure? Type 'CLEANUP' to confirm: " confirm
    
    if [ "$confirm" != "CLEANUP" ]; then
        echo "Cancelled"
        sleep 2
        return
    fi
    
    echo ""
    echo "Removing containers..."
    docker stop $(docker ps -a --filter "name=team" -q) 2>/dev/null
    docker rm $(docker ps -a --filter "name=team" -q) 2>/dev/null
    docker stop $(docker ps -a --filter "name=substation" -q) 2>/dev/null
    docker rm $(docker ps -a --filter "name=substation" -q) 2>/dev/null
    docker stop openplc scadabr kali-workstation 2>/dev/null
    docker rm openplc scadabr kali-workstation 2>/dev/null
    
    echo "Removing images..."
    docker rmi $(docker images --filter "reference=*breaker*" -q) 2>/dev/null
    docker rmi $(docker images --filter "reference=*control*" -q) 2>/dev/null
    docker rmi $(docker images --filter "reference=*kali*" -q) 2>/dev/null
    docker rmi $(docker images --filter "reference=*openplc*" -q) 2>/dev/null
    docker rmi $(docker images --filter "reference=*scadabr*" -q) 2>/dev/null
    
    echo "Removing networks..."
    docker network rm $(docker network ls --filter "name=team" -q) 2>/dev/null
    
    echo ""
    echo -e "${GREEN}✓ Cleanup complete${NC}"
    read -p "Press Enter to continue..."
}

# ============================================================================
# UPDATE MENU
# ============================================================================

update_menu() {
    while true; do
        show_header
        echo -e "${MAGENTA}═══ Updates & Git ═══${NC}"
        echo ""
        echo "  1) Check for Updates"
        echo "  2) Pull Latest Changes"
        echo "  3) Stash Local Changes"
        echo "  4) Update and Rebuild"
        echo "  5) View Git Status"
        echo "  6) View Git Log"
        echo "  b) Back to Main Menu"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) check_updates ;;
            2) pull_updates ;;
            3) stash_changes ;;
            4) update_rebuild ;;
            5) git_status ;;
            6) git_log ;;
            b|B) return ;;
            *) echo -e "${RED}Invalid choice${NC}"; sleep 1 ;;
        esac
    done
}

check_updates() {
    show_header
    echo -e "${YELLOW}Checking for Updates${NC}"
    echo ""
    
    if ! check_repo; then
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "Fetching from remote..."
    git fetch origin
    
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
    
    if [ $LOCAL = $REMOTE ]; then
        echo -e "${GREEN}✓ Already up to date${NC}"
    else
        echo -e "${YELLOW}⚠️  Updates available${NC}"
        echo ""
        echo "Changes:"
        git log HEAD..@{u} --oneline
    fi
    
    read -p "Press Enter to continue..."
}

pull_updates() {
    show_header
    echo -e "${YELLOW}Pulling Latest Changes${NC}"
    echo ""
    
    if ! check_repo; then
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "Pulling from remote..."
    git pull
    
    echo ""
    echo "Updating submodules..."
    git submodule update --init --recursive
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ Updated successfully${NC}"
    else
        echo -e "${RED}✗ Update failed${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

stash_changes() {
    show_header
    echo -e "${YELLOW}Stash Local Changes${NC}"
    echo ""
    
    if ! check_repo; then
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "Current changes:"
    git status --short
    
    echo ""
    read -p "Stash these changes? (y/n): " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        git stash push -m "Stashed by ctf-admin $(date '+%Y-%m-%d %H:%M:%S')"
        echo -e "${GREEN}✓ Changes stashed${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

update_rebuild() {
    show_header
    echo -e "${YELLOW}Update and Rebuild${NC}"
    echo ""
    
    if ! check_repo; then
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "This will:"
    echo "  1. Stash local changes"
    echo "  2. Pull latest updates"
    echo "  3. Update submodules"
    echo "  4. Rebuild Docker images"
    echo ""
    read -p "Continue? (y/n): " confirm
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        return
    fi
    
    echo ""
    echo "Stashing changes..."
    git stash
    
    echo "Pulling updates..."
    git pull
    
    echo "Updating submodules..."
    git submodule update --init --recursive
    
    echo "Rebuilding images..."
    cd deployment
    docker-compose -f docker-compose-ctf-final.yml build
    cd ..
    
    echo ""
    echo -e "${GREEN}✓ Update and rebuild complete${NC}"
    read -p "Press Enter to continue..."
}

git_status() {
    show_header
    echo -e "${YELLOW}Git Status${NC}"
    echo ""
    
    if ! check_repo; then
        read -p "Press Enter to continue..."
        return
    fi
    
    git status
    
    echo ""
    read -p "Press Enter to continue..."
}

git_log() {
    show_header
    echo -e "${YELLOW}Git Log (Last 10 commits)${NC}"
    echo ""
    
    if ! check_repo; then
        read -p "Press Enter to continue..."
        return
    fi
    
    git log --oneline --graph --decorate -10
    
    echo ""
    read -p "Press Enter to continue..."
}

# ============================================================================
# MANAGEMENT MENU (Existing functionality)
# ============================================================================

management_menu() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/ctf-manager.sh" ]; then
        bash "$SCRIPT_DIR/ctf-manager.sh"
    else
        show_header
        echo -e "${RED}ctf-manager.sh not found at $SCRIPT_DIR${NC}"
        echo ""
        echo "Expected location: $SCRIPT_DIR/ctf-manager.sh"
        echo "Current directory: $(pwd)"
        echo ""
        read -p "Press Enter to continue..."
    fi
}

# ============================================================================
# MAIN MENU
# ============================================================================

main_menu() {
    while true; do
        show_header
        show_quick_stats
        
        echo -e "${YELLOW}Main Menu:${NC}"
        echo "  1) Installation & Setup"
        echo "  2) Deployment"
        echo "  3) Updates & Git"
        echo "  4) CTF Management (Status, Logs, etc.)"
        echo "  5) System Information"
        echo "  6) Team Access Details"
        echo "  q) Quit"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) install_menu ;;
            2) deployment_menu ;;
            3) update_menu ;;
            4) management_menu ;;
            5) system_info ;;
            6) team_access ;;
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

system_info() {
    show_header
    echo -e "${YELLOW}System Information${NC}"
    echo ""
    
    echo "Docker Version:"
    docker --version
    echo ""
    
    echo "Docker Compose Version:"
    docker-compose --version
    echo ""
    
    echo "Git Version:"
    git --version
    echo ""
    
    echo "Disk Usage:"
    df -h / | tail -1
    echo ""
    
    echo "Memory Usage:"
    free -h | grep Mem
    echo ""
    
    echo "Docker Images:"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "breaker|control|kali|openplc|scadabr|REPOSITORY"
    
    echo ""
    read -p "Press Enter to continue..."
}

team_access() {
    show_header
    echo -e "${YELLOW}Team Access Details${NC}"
    echo ""
    
    # Get VM IP
    VM_IP=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H "Metadata-Flavor: Google" 2>/dev/null || hostname -I | awk '{print $1}')
    
    # Count deployed teams
    TEAM_COUNT=$(docker ps --filter "name=team" --format "{{.Names}}" | grep -o "team[0-9]\+" | sort -u | wc -l)
    
    if [ $TEAM_COUNT -eq 0 ]; then
        echo -e "${RED}No teams deployed${NC}"
        echo ""
        read -p "Press Enter to continue..."
        return
    fi
    
    # Find latest credentials file
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CREDS_FILE=$(ls -t "$SCRIPT_DIR"/team_credentials_*.txt 2>/dev/null | head -1)
    
    echo -e "${CYAN}VM IP: $VM_IP${NC}"
    echo -e "${CYAN}Teams Deployed: $TEAM_COUNT${NC}"
    if [ -n "$CREDS_FILE" ]; then
        echo -e "${CYAN}Credentials: Custom (from $(basename "$CREDS_FILE"))${NC}"
    else
        echo -e "${CYAN}Credentials: Default${NC}"
    fi
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    for i in $(seq 1 $TEAM_COUNT); do
        TEAM_ID="team${i}"
        SSH_PORT=$((20000 + i))  # Maps to container port 22
        
        # Check if team exists
        if ! docker ps --format "{{.Names}}" | grep -q "^${TEAM_ID}-kali$"; then
            continue
        fi
        
        # Get password - check if container is newer than credentials file
        PASSWORD="IEC61850_CTF_2024"
        if [ -n "$CREDS_FILE" ]; then
            CONTAINER_CREATED=$(docker inspect -f '{{.Created}}' ${TEAM_ID}-kali 2>/dev/null | date -d "$(cat -)" +%s 2>/dev/null || echo 0)
            CREDS_MODIFIED=$(stat -c %Y "$CREDS_FILE" 2>/dev/null || echo 0)
            
            # Only use credentials file if it's newer than container
            if [ $CREDS_MODIFIED -gt $CONTAINER_CREATED ]; then
                PASSWORD=$(grep -A 3 "^Team: $TEAM_ID" "$CREDS_FILE" | grep "^Password:" | awk '{print $2}')
                [ -z "$PASSWORD" ] && PASSWORD="IEC61850_CTF_2024"
            fi
        fi
        
        echo -e "${GREEN}Team $i:${NC}"
        echo -e "  ${CYAN}1. SSH Access:${NC}"
        echo "     ssh ctfuser@$VM_IP -p $SSH_PORT"
        echo "     Password: $PASSWORD"
        echo ""
        echo -e "  ${CYAN}2. Port Forward Web UIs:${NC}"
        echo "     ssh -L 9001:${TEAM_ID}-breaker-v1:9000 -L 9002:${TEAM_ID}-breaker-v2:9000 \\"
        echo "         -L 8081:${TEAM_ID}-openplc:8080 -L 8080:${TEAM_ID}-scadabr:8080 \\"
        echo "         ctfuser@$VM_IP -p $SSH_PORT"
        echo ""
        echo -e "  ${CYAN}3. Access Web Interfaces (after port forward):${NC}"
        echo "     Breaker v1:  http://localhost:9001"
        echo "     Breaker v2:  http://localhost:9002"
        echo "     OpenPLC:     http://localhost:8081 (openplc/openplc)"
        echo "     ScadaBR:     http://localhost:8080/ScadaBR (admin/admin)"
        echo ""
    done
    
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo -e "${YELLOW}Note: Teams are isolated and cannot access each other${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

# Start the application
main_menu
