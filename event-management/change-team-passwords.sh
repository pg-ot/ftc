#!/bin/bash
# Generate and change passwords for all deployed teams

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         Change Team Passwords                                  ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get VM IP
VM_IP=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H "Metadata-Flavor: Google" 2>/dev/null || hostname -I | awk '{print $1}')

# Count deployed teams
TEAM_COUNT=$(docker ps --filter "name=team" --format "{{.Names}}" | grep -o "team[0-9]\+" | sort -u | wc -l)

if [ $TEAM_COUNT -eq 0 ]; then
    echo -e "${RED}No teams deployed${NC}"
    exit 1
fi

echo -e "${YELLOW}Found $TEAM_COUNT deployed teams${NC}"
echo ""
read -p "Generate and change passwords for all teams? (y/n): " confirm

if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

# Output file
OUTPUT_FILE="team_credentials_$(date +%Y%m%d_%H%M%S).txt"

echo ""
echo -e "${YELLOW}Generating passwords and updating containers...${NC}"
echo ""

# Create output file with header
cat > "$OUTPUT_FILE" << EOF
IEC 61850 GOOSE CTF - Team Credentials
Generated: $(date '+%Y-%m-%d %H:%M:%S')
VM IP: $VM_IP
========================================

EOF

for i in $(seq 1 $TEAM_COUNT); do
    TEAM_ID="team${i}"
    SSH_PORT=$((20000 + i))  # Maps to container port 22
    
    # Check if Kali container exists
    if ! docker ps --format "{{.Names}}" | grep -q "^${TEAM_ID}-kali$"; then
        echo -e "${RED}✗ ${TEAM_ID}-kali not found, skipping${NC}"
        continue
    fi
    
    # Generate password
    PASSWORD=$(openssl rand -base64 12 | tr -d '/+=' | head -c 8)
    
    echo "  Generating password for ${TEAM_ID}: ${PASSWORD}"
    
    # Ensure ctfuser exists and change password
    docker exec ${TEAM_ID}-kali bash -c "
        useradd -m -s /bin/bash ctfuser 2>/dev/null || true
        usermod -aG sudo ctfuser 2>/dev/null || true
        echo 'ctfuser:${PASSWORD}' | chpasswd
    " 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ ${TEAM_ID}: Password changed to ${PASSWORD}${NC}"
        
        # Verify password was set
        VERIFY=$(docker exec ${TEAM_ID}-kali bash -c "echo '${PASSWORD}' | su - ctfuser -c 'echo OK'" 2>/dev/null)
        if [ "$VERIFY" = "OK" ]; then
            echo "  Verification: Password correctly set"
        else
            echo -e "  ${YELLOW}Warning: Could not verify password${NC}"
        fi
        
        # Write to file
        cat >> "$OUTPUT_FILE" << EOF
Team: $TEAM_ID
----------------------------------------
Username: ctfuser
Password: $PASSWORD
SSH Port: $SSH_PORT
SSH Command: ssh ctfuser@$VM_IP -p $SSH_PORT

EOF
    else
        echo -e "${RED}✗ ${TEAM_ID}: Failed to change password${NC}"
    fi
done

# Add footer
cat >> "$OUTPUT_FILE" << EOF

========================================
Total Teams: $TEAM_COUNT

IMPORTANT:
- Distribute via CTFd
- Never commit to Git
- Teams are network isolated
EOF

echo ""
echo "=========================================="
echo -e "${GREEN}✓ Passwords changed successfully${NC}"
echo -e "${GREEN}✓ Credentials saved to: $OUTPUT_FILE${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Distribute credentials via CTFd"
echo "  2. Keep $OUTPUT_FILE secure"
echo "  3. Delete file after distribution"
echo ""
