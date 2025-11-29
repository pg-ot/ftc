#!/bin/bash
# Make all scripts executable

echo "Making all scripts executable..."

chmod +x start.sh
chmod +x ctf-admin.sh
chmod +x ctf-manager.sh
chmod +x status.sh
chmod +x restart-all.sh
chmod +x restart-team.sh
chmod +x reset-team.sh
chmod +x reset-breaker.sh
chmod +x logs.sh
chmod +x monitor.sh
chmod +x check-flags.sh
chmod +x network-check.sh
chmod +x network-isolation-test.sh
chmod +x test-all-networks.sh
chmod +x emergency-stop.sh
chmod +x backup.sh

echo "✓ Done"
echo ""
echo "To start the interactive manager:"
echo "  ./start.sh"
echo ""
echo "All available scripts:"
ls -lh *.sh
