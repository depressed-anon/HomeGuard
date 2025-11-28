#!/bin/bash
# Mullvad VPN Configuration for HomeGuard

set -e

CREDENTIALS_FILE="$1"
source "$CREDENTIALS_FILE"

# Mullvad uses WireGuard
if [ -z "$VPN_ACCOUNT" ]; then
    echo "ERROR: VPN_ACCOUNT not set"
    exit 1
fi

echo "Configuring Mullvad VPN (WireGuard)..."

# Download Mullvad WireGuard config
# Users can get this from https://mullvad.net/en/account/#/wireguard-config/

# For automated setup, we'll use Mullvad's API to generate config
MULLVAD_API="https://api.mullvad.net/wg/"

# Generate WireGuard keys
PRIVATE_KEY=$(wg genkey)
PUBLIC_KEY=$(echo "$PRIVATE_KEY" | wg pubkey)

# Register public key with Mullvad
RESPONSE=$(curl -sSLX POST https://api.mullvad.net/wg/ \
    -d account="$VPN_ACCOUNT" \
    -d pubkey="$PUBLIC_KEY")

if echo "$RESPONSE" | grep -q "error"; then
    echo "ERROR: Mullvad account validation failed"
    echo "$RESPONSE"
    exit 1
fi

# Extract Mullvad server details
MULLVAD_SERVER=$(echo "$RESPONSE" | jq -r '.ipv4_gateway')
MULLVAD_PORT=$(echo "$RESPONSE" | jq -r '.port // "51820"')
MULLVAD_IP=$(echo "$RESPONSE" | jq -r '.ipv4_address')
MULLVAD_DNS=$(echo "$RESPONSE" | jq -r '.ipv4_dns // "10.64.0.1"')

# Get a random Mullvad server (default to Sweden)
SERVER_PUBLIC_KEY="dEjKY8WxXyqN3/VPQaPYVZqg0CwHT6DXZaojJdH8wlg="  # Mullvad SE server

# Create WireGuard config
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Address = $MULLVAD_IP/32
DNS = $MULLVAD_DNS

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
AllowedIPs = 0.0.0.0/0
Endpoint = $MULLVAD_SERVER:$MULLVAD_PORT
PersistentKeepalive = 25
EOF

chmod 600 /etc/wireguard/wg0.conf

# Create systemd service
cat > /etc/systemd/system/homeguard-vpn.service <<EOFSERVICE
[Unit]
Description=HomeGuard VPN (Mullvad WireGuard)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/wg-quick up wg0
ExecStop=/usr/bin/wg-quick down wg0
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOFSERVICE

# Enable and start
systemctl daemon-reload
systemctl enable homeguard-vpn.service
systemctl start homeguard-vpn.service

echo "✓ Mullvad WireGuard configured and started"
