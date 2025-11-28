#!/bin/bash
# HomeGuard Pro - VPN Configuration Master Script
# This script is called by the setup wizard to configure VPN client

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "$1" | tee -a /var/log/homeguard-vpn-setup.log
}

error_exit() {
    log "${RED}ERROR: $1${NC}"
    exit 1
}

# Parse arguments
PROVIDER="$1"
CREDENTIALS_FILE="$2"

if [ -z "$PROVIDER" ] || [ -z "$CREDENTIALS_FILE" ]; then
    error_exit "Usage: $0 <provider> <credentials_file>"
fi

if [ ! -f "$CREDENTIALS_FILE" ]; then
    error_exit "Credentials file not found: $CREDENTIALS_FILE"
fi

# Source credentials
source "$CREDENTIALS_FILE"

log "${BLUE}Configuring VPN: $PROVIDER${NC}"

# Install VPN clients
log "${YELLOW}Installing VPN software...${NC}"
apt-get update -qq
apt-get install -y openvpn wireguard-tools resolvconf >> /var/log/homeguard-vpn-setup.log 2>&1

# Call provider-specific setup script
SCRIPT_DIR="$(dirname "$0")"
PROVIDER_SCRIPT="$SCRIPT_DIR/providers/${PROVIDER}.sh"

if [ ! -f "$PROVIDER_SCRIPT" ]; then
    error_exit "Provider script not found: $PROVIDER_SCRIPT"
fi

log "${YELLOW}Running ${PROVIDER} configuration...${NC}"
bash "$PROVIDER_SCRIPT" "$CREDENTIALS_FILE"

if [ $? -ne 0 ]; then
    error_exit "VPN configuration failed"
fi

# Configure routing
log "${YELLOW}Configuring network routing...${NC}"

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Get VPN interface (tun0 for OpenVPN, wg0 for WireGuard)
VPN_INTERFACE=""
if ip link show tun0 &>/dev/null; then
    VPN_INTERFACE="tun0"
elif ip link show wg0 &>/dev/null; then
    VPN_INTERFACE="wg0"
else
    error_exit "VPN interface not found (tun0 or wg0)"
fi

log "${GREEN}VPN interface: $VPN_INTERFACE${NC}"

# Configure iptables to route traffic through VPN
log "${YELLOW}Configuring firewall rules...${NC}"

# Get local interface (eth0 or wlan0)
LOCAL_INTERFACE=$(ip route | grep default | grep -oP '(?<=dev )\S+' | head -1)

# NAT traffic through VPN
iptables -t nat -A POSTROUTING -o $VPN_INTERFACE -j MASQUERADE

# Allow forwarding to VPN
iptables -A FORWARD -i br0 -o $VPN_INTERFACE -j ACCEPT 2>/dev/null || iptables -A FORWARD -i $LOCAL_INTERFACE -o $VPN_INTERFACE -j ACCEPT
iptables -A FORWARD -i $VPN_INTERFACE -m state --state ESTABLISHED,RELATED -j ACCEPT

# Kill switch: Block traffic if VPN down (except local network)
iptables -A FORWARD -o $LOCAL_INTERFACE ! -d 192.168.0.0/16 -j DROP
iptables -A FORWARD -o $LOCAL_INTERFACE ! -d 10.0.0.0/8 -j DROP
iptables -A FORWARD -o $LOCAL_INTERFACE ! -d 172.16.0.0/12 -j DROP

# Save iptables rules
netfilter-persistent save

log "${GREEN}✓ Firewall configured with kill switch${NC}"

# Configure DNS to use VPN DNS
log "${YELLOW}Configuring DNS...${NC}"

# Get VPN DNS servers from connection
VPN_DNS=$(grep nameserver /etc/resolv.conf | grep -v 127.0.0.1 | head -1 | awk '{print $2}')

if [ -n "$VPN_DNS" ]; then
    log "${GREEN}Using VPN DNS: $VPN_DNS${NC}"

    # Update Pi-hole to use VPN DNS for upstream
    pihole -a setdns $VPN_DNS
else
    log "${YELLOW}Could not detect VPN DNS, using defaults${NC}"
fi

# Create VPN management commands
log "${YELLOW}Creating management commands...${NC}"

cat > /usr/local/bin/homeguard-vpn <<'EOFCMD'
#!/bin/bash
# HomeGuard VPN Management

VPN_PROVIDER="__PROVIDER__"
VPN_INTERFACE="__VPN_INTERFACE__"

case "$1" in
    status)
        echo "HomeGuard VPN Status"
        echo "===================="
        echo ""

        if ip link show $VPN_INTERFACE &>/dev/null && ip addr show $VPN_INTERFACE | grep -q "inet "; then
            echo "✓ VPN: Connected"
            echo "  Provider: $VPN_PROVIDER"
            echo "  Interface: $VPN_INTERFACE"

            # Get VPN IP
            VPN_IP=$(curl -s https://api.ipify.org)
            echo "  Public IP: $VPN_IP"
        else
            echo "✗ VPN: Disconnected"
            echo ""
            echo "⚠️  WARNING: Kill switch active - No internet until VPN reconnects"
        fi
        ;;

    connect)
        echo "Connecting to $VPN_PROVIDER VPN..."
        systemctl start homeguard-vpn
        sleep 3
        $0 status
        ;;

    disconnect)
        echo "Disconnecting from VPN..."
        systemctl stop homeguard-vpn
        echo "✓ VPN disconnected"
        echo ""
        echo "⚠️  WARNING: Kill switch active - No internet access"
        ;;

    restart)
        echo "Restarting VPN connection..."
        systemctl restart homeguard-vpn
        sleep 3
        $0 status
        ;;

    logs)
        journalctl -u homeguard-vpn -n 50 --no-pager
        ;;

    test)
        echo "Testing VPN connection..."
        echo ""

        # Test 1: VPN interface up?
        if ip link show $VPN_INTERFACE &>/dev/null; then
            echo "✓ VPN interface is up"
        else
            echo "✗ VPN interface is down"
        fi

        # Test 2: Can reach internet through VPN?
        if ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
            echo "✓ Internet connectivity working"
        else
            echo "✗ No internet connectivity"
        fi

        # Test 3: DNS leak test
        echo ""
        echo "Public IP: $(curl -s https://api.ipify.org)"
        echo "DNS Servers:"
        dig +short myip.opendns.com @resolver1.opendns.com
        ;;

    *)
        echo "HomeGuard VPN Management"
        echo ""
        echo "Usage: $0 {status|connect|disconnect|restart|logs|test}"
        echo ""
        echo "Commands:"
        echo "  status      - Show VPN connection status"
        echo "  connect     - Connect to VPN"
        echo "  disconnect  - Disconnect from VPN"
        echo "  restart     - Restart VPN connection"
        echo "  logs        - View VPN logs"
        echo "  test        - Test VPN connection and check for leaks"
        exit 1
        ;;
esac
EOFCMD

# Replace placeholders
sed -i "s/__PROVIDER__/$PROVIDER/g" /usr/local/bin/homeguard-vpn
sed -i "s/__VPN_INTERFACE__/$VPN_INTERFACE/g" /usr/local/bin/homeguard-vpn
chmod +x /usr/local/bin/homeguard-vpn

log "${GREEN}✓ VPN management command created: homeguard-vpn${NC}"

# Test VPN connection
log "${YELLOW}Testing VPN connection...${NC}"
sleep 3

if ip addr show $VPN_INTERFACE | grep -q "inet "; then
    VPN_IP=$(curl -s https://api.ipify.org)
    log "${GREEN}✓ VPN connected successfully!${NC}"
    log "${GREEN}  Public IP: $VPN_IP${NC}"
else
    log "${YELLOW}⚠ VPN may not be connected yet (can take 10-30 seconds)${NC}"
fi

log "${GREEN}═══ VPN Configuration Complete ═══${NC}"
log ""
log "Test your VPN:"
log "  ${BLUE}homeguard-vpn status${NC}  - Check status"
log "  ${BLUE}homeguard-vpn test${NC}    - Test for DNS leaks"
log ""
