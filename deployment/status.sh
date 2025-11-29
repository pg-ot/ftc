#!/bin/bash
# Check status of CTF deployment

echo "=== CTF Environment Status ==="
echo ""

docker-compose -f docker-compose-ctf-final.yml ps

echo ""
echo "=== Network Configuration ==="
echo ""

# Check Kali network access
if docker ps --format "{{.Names}}" | grep -q "kali-workstation"; then
    echo "Kali Workstation Networks:"
    docker inspect kali-workstation --format="  Mahashakti:  {{(index .NetworkSettings.Networks \"deployment_mahashakti\").IPAddress}}" 2>/dev/null || echo "  Mahashakti:  Not connected"
    docker inspect kali-workstation --format="  Aushadi Raksha: {{(index .NetworkSettings.Networks \"deployment_aushadi_raksha\").IPAddress}}" 2>/dev/null || echo "  Aushadi Raksha: Not connected"
else
    echo "Kali Workstation: Not running"
fi

echo ""
echo "=== Container Status ==="
echo "IED Containers:"
docker ps --filter "name=substation" --format "  {{.Names}}: {{.Status}}"
echo ""
echo "SCADA Containers:"
docker ps --filter "name=openplc" --format "  {{.Names}}: {{.Status}}"
docker ps --filter "name=scadabr" --format "  {{.Names}}: {{.Status}}"
echo ""
echo "Workstation:"
docker ps --filter "name=kali" --format "  {{.Names}}: {{.Status}}"

echo ""
echo "=== Access URLs ==="
echo "  Breaker v1:  http://localhost:9001"
echo "  Breaker v2:  http://localhost:9002"
echo "  OpenPLC:     http://localhost:8081"
echo "  ScadaBR:     http://localhost:8080"
echo "  Modbus TCP:  localhost:502"
