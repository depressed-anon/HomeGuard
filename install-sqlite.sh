#!/bin/bash
# Install sqlite3 on Parrot OS to manage Pi-hole database

echo "Installing sqlite3 on your system..."
sudo apt-get update
sudo apt-get install -y sqlite3

echo ""
echo "✅ sqlite3 installed!"
echo ""
echo "You can now manage Pi-hole's database directly:"
echo "  podman cp pihole:/etc/pihole/gravity.db ./pihole-gravity.db"
echo "  sqlite3 ./pihole-gravity.db"
echo ""
