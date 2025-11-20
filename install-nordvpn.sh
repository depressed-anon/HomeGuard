#!/bin/bash
# Install and configure NordVPN with Pi-hole DNS

echo "=== NordVPN Installation Guide ==="
echo ""
echo "Installing NordVPN for Linux..."
echo ""

# Download NordVPN repository
echo "Step 1: Adding NordVPN repository..."
sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)

echo ""
echo "Step 2: Login to NordVPN..."
echo "Run: nordvpn login"
echo ""
echo "Step 3: Configure to use Pi-hole DNS..."
echo "Run these commands:"
echo "  nordvpn set dns 127.0.0.1"
echo "  nordvpn set technology nordlynx"
echo "  nordvpn set killswitch on"
echo "  nordvpn set autoconnect on"
echo ""
echo "Step 4: Connect to VPN..."
echo "Run: nordvpn connect"
echo ""
echo "Step 5: Verify DNS is using Pi-hole..."
echo "Run: dig google.com | grep SERVER"
echo "Should show: 127.0.0.1"
echo ""
echo "✅ Done! Your traffic now flows:"
echo "   Apps → Pi-hole (blocks ads) → NordVPN (encrypts) → Internet"
