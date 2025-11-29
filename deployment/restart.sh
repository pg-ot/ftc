#!/bin/bash
# Restart all CTF containers

echo "Restarting CTF environment..."
docker-compose -f docker-compose-ctf-final.yml restart

echo ""
echo "Waiting for containers to be ready..."
sleep 5

echo ""
docker-compose -f docker-compose-ctf-final.yml ps

echo ""
echo "✓ Restart complete!"
