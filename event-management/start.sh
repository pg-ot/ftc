#!/bin/bash
# Quick launcher for CTF Admin Tool

# Make sure all scripts are executable
chmod +x *.sh 2>/dev/null

# Check if we should launch admin or manager
if [ "$1" = "--manage" ] || [ "$1" = "-m" ]; then
    # Launch management only
    ./ctf-manager.sh
else
    # Launch comprehensive admin tool
    ./ctf-admin.sh
fi
