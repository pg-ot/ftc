#!/bin/bash

echo "Building Power Plant CTF Containers..."

# Build all containers
docker-compose -f docker-compose-ctf-final.yml build

echo "Containers built successfully!"
echo ""
echo "To start the CTF environment:"
echo "  docker-compose -f docker-compose-ctf-final.yml up -d"
echo ""
echo "Flag server will be available at: http://localhost:9000"