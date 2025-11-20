#!/bin/bash
# Set up WireGuard VPN for traffic encryption

echo "=== WireGuard VPN Setup ==="
echo ""
echo "WireGuard encrypts ALL your traffic, protecting against:"
echo "  ✓ ISP surveillance"
echo "  ✓ Public WiFi attacks"
echo "  ✓ Traffic analysis"
echo ""
echo "Choose your setup option:"
echo ""
echo "1. Self-Hosted VPN Server (Maximum Privacy)"
echo "   - Requires: VPS ($5/month) or home server"
echo "   - Privacy: Best (you control everything)"
echo "   - Setup: 15-30 minutes"
echo ""
echo "2. Add WireGuard to Container Stack (Easy)"
echo "   - Runs locally alongside Pi-hole"
echo "   - Can create VPN server for remote access"
echo "   - Setup: 5 minutes"
echo ""
echo "3. Use Commercial VPN (Easiest)"
echo "   - Mullvad ($5/month) - Best privacy, accepts crypto"
echo "   - ProtonVPN ($5-10/month)"
echo "   - Privacy: Good (trust provider)"
echo "   - Setup: 2 minutes"
echo ""
read -p "Choose option (1/2/3) or press Enter to skip: " choice

case "$choice" in
    1)
        echo ""
        echo "Self-Hosted VPN Setup Instructions:"
        echo ""
        echo "1. Get a VPS (DigitalOcean, Linode, Vultr - $5/month)"
        echo "2. Install WireGuard:"
        echo "   sudo apt install wireguard"
        echo ""
        echo "3. Generate keys:"
        echo "   wg genkey | tee server_private.key | wg pubkey > server_public.key"
        echo ""
        echo "4. Configure /etc/wireguard/wg0.conf (see wireguard-server-config.txt)"
        echo ""
        echo "5. Enable and start:"
        echo "   sudo systemctl enable wg-quick@wg0"
        echo "   sudo systemctl start wg-quick@wg0"
        echo ""
        echo "Full guide: https://www.wireguard.com/quickstart/"
        ;;
    2)
        echo ""
        echo "Adding WireGuard to your security stack..."
        echo ""
        # Add WireGuard to docker-compose
        cat >> ~/security-stack/docker-compose.yml << 'EOF'

  # WireGuard VPN
  wireguard:
    image: docker.io/linuxserver/wireguard:latest
    container_name: wireguard
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - SERVERURL=auto
      - SERVERPORT=51820
      - PEERS=laptop,phone
      - PEERDNS=127.0.0.1  # Use your Pi-hole!
      - ALLOWEDIPS=0.0.0.0/0
    ports:
      - 51820:51820/udp
    volumes:
      - ./wireguard:/config
      - /lib/modules:/lib/modules
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    networks:
      - security-net
EOF
        echo "✅ WireGuard added to docker-compose.yml"
        echo ""
        echo "Restart stack:"
        echo "  cd ~/security-stack"
        echo "  ./manage.sh restart"
        echo ""
        echo "Get client configs:"
        echo "  ls ~/security-stack/wireguard/peer_*/*.conf"
        ;;
    3)
        echo ""
        echo "Recommended Commercial VPNs:"
        echo ""
        echo "1. Mullvad VPN (Best Privacy)"
        echo "   - $5/month flat"
        echo "   - No email required"
        echo "   - Accepts crypto"
        echo "   - https://mullvad.net"
        echo ""
        echo "2. ProtonVPN"
        echo "   - $5-10/month"
        echo "   - Good privacy policy"
        echo "   - https://protonvpn.com"
        echo ""
        echo "After signing up, install their client and configure:"
        echo "  Custom DNS: 127.0.0.1 (to use your Pi-hole)"
        ;;
    *)
        echo "Skipping VPN setup for now."
        echo "You can run this script again anytime."
        ;;
esac

echo ""
echo "Done!"
