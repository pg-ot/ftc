#!/bin/bash
# Quick deployment script for CTF environment

set -e

echo "=== IEC 61850 GOOSE CTF Deployment ==="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "✓ Docker is running"
echo ""

# Check for required images
echo "Checking for required images..."
MISSING_IMAGES=0

if ! docker images | grep -q "openplc-configured"; then
    echo "❌ openplc-configured image not found"
    MISSING_IMAGES=1
fi

if ! docker images | grep -q "scadabr-configured"; then
    echo "❌ scadabr-configured image not found"
    MISSING_IMAGES=1
fi

if [ $MISSING_IMAGES -eq 1 ]; then
    echo ""
    echo "Missing SCADA images. Please load them first:"
    echo "  docker load -i openplc-configured.tar"
    echo "  docker load -i scadabr-configured.tar"
    exit 1
fi

echo "✓ All required images found"
echo ""

# Stop existing containers
echo "Stopping existing containers..."
docker-compose -f docker-compose-ctf-final.yml down 2>/dev/null || true

# Start new deployment
echo ""
echo "Starting CTF environment..."
docker-compose -f docker-compose-ctf-final.yml up -d

# Wait for containers to be ready
echo ""
echo "Waiting for containers to start..."
sleep 5

# Check status
echo ""
echo "=== Deployment Status ==="
docker-compose -f docker-compose-ctf-final.yml ps

echo ""
echo "=== Access URLs ==="
echo "  Breaker v1:  http://localhost:9001"
echo "  Breaker v2:  http://localhost:9002"
echo "  OpenPLC:     http://localhost:8081 (openplc/openplc)"
echo "  ScadaBR:     http://localhost:8080/ScadaBR (admin/admin)"
echo "  Modbus TCP:  localhost:502"
echo ""
echo "=== Kali Access ==="
echo "  docker exec -it kali-workstation bash"
echo ""
echo "✓ Deployment complete!"
