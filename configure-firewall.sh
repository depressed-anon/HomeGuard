#!/bin/bash
# Configure UFW firewall for security stack

echo "Configuring firewall..."

# Enable UFW
sudo ufw --force enable

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (if you need remote access)
# sudo ufw allow 22/tcp

# Allow local connections (for your containers)
sudo ufw allow from 127.0.0.1

# If you want other devices on LAN to use your DNS/proxies:
# sudo ufw allow from 192.168.0.0/24 to any port 53 proto udp
# sudo ufw allow from 192.168.0.0/24 to any port 53 proto tcp
# sudo ufw allow from 192.168.0.0/24 to any port 3128 proto tcp
# sudo ufw allow from 192.168.0.0/24 to any port 1080 proto tcp

# Show status
sudo ufw status verbose

echo "Firewall configured! Only localhost connections allowed."
echo "Uncomment lines in this script to allow LAN access."
