#!/bin/bash
# Stop all CTF containers

echo "Stopping CTF environment..."
docker-compose -f docker-compose-ctf-final.yml down

echo "✓ All containers stopped"
