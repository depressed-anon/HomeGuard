#!/bin/bash
# NordVPN Configuration for HomeGuard

set -e

CREDENTIALS_FILE="$1"
source "$CREDENTIALS_FILE"

if [ -z "$VPN_USERNAME" ] || [ -z "$VPN_PASSWORD" ]; then
    echo "ERROR: VPN_USERNAME or VPN_PASSWORD not set"
    exit 1
fi

echo "Configuring NordVPN (OpenVPN)..."

# Install NordVPN (they have their own CLI)
sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh) || {
    echo "ERROR: Failed to install NordVPN client"
    exit 1
}

# Login to NordVPN
echo "$VPN_PASSWORD" | nordvpn login --username "$VPN_USERNAME"

if [ $? -ne 0 ]; then
    echo "ERROR: NordVPN login failed"
    exit 1
fi

# Configure NordVPN
nordvpn set killswitch on
nordvpn set autoconnect on
nordvpn set dns off  # Use Pi-hole for DNS

# Connect to fastest server
nordvpn connect

# Create systemd service wrapper
cat > /etc/systemd/system/homeguard-vpn.service <<EOFSERVICE
[Unit]
Description=HomeGuard VPN (NordVPN)
After=network-online.target nordvpnd.service
Requires=nordvpnd.service
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/nordvpn connect
ExecStop=/usr/bin/nordvpn disconnect
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOFSERVICE

systemctl daemon-reload
systemctl enable homeguard-vpn.service

echo "✓ NordVPN configured and started"
