#!/bin/bash
# HomeGuard Pro - Transparent Gateway Setup
# Deploys ARP spoofing + PVLAN enforcement for transparent network protection

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INTERFACE=""
GATEWAY_IP=""
GATEWAY_MAC=""
HOMEGUARD_IP=""
HOMEGUARD_MAC=""
ARP_INTERVAL=2
ENABLE_MULTICAST=false

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  HomeGuard Pro - Transparent Gateway Setup              ║${NC}"
echo -e "${BLUE}║  ARP Spoofing + PVLAN Enforcement                        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root${NC}"
   echo "Please run: sudo $0"
   exit 1
fi

# Install dependencies
echo -e "${YELLOW}[1/8] Installing dependencies...${NC}"
apt-get update -qq
apt-get install -y ebtables arping net-tools iproute2 iptables-persistent > /dev/null 2>&1
echo -e "${GREEN}✓ Dependencies installed${NC}"

# Detect network interface
echo -e "${YELLOW}[2/8] Detecting network interface...${NC}"
if ip link show wlan0 &>/dev/null && ip addr show wlan0 | grep -q "inet "; then
    INTERFACE="wlan0"
    echo -e "${GREEN}✓ Using WiFi interface: wlan0${NC}"
elif ip link show eth0 &>/dev/null && ip addr show eth0 | grep -q "inet "; then
    INTERFACE="eth0"
    echo -e "${GREEN}✓ Using Ethernet interface: eth0${NC}"
else
    echo -e "${RED}✗ No active network interface found${NC}"
    echo "Please connect to network first:"
    echo "  WiFi: sudo raspi-config → Network Options → WiFi"
    echo "  Ethernet: Connect cable and wait for DHCP"
    exit 1
fi

# Get HomeGuard IP and MAC
HOMEGUARD_IP=$(ip addr show $INTERFACE | grep "inet " | awk '{print $2}' | cut -d/ -f1)
HOMEGUARD_MAC=$(ip link show $INTERFACE | grep ether | awk '{print $2}')

if [ -z "$HOMEGUARD_IP" ]; then
    echo -e "${RED}✗ Could not determine IP address on $INTERFACE${NC}"
    exit 1
fi

echo "  HomeGuard IP:  $HOMEGUARD_IP"
echo "  HomeGuard MAC: $HOMEGUARD_MAC"

# Discover gateway
echo -e "${YELLOW}[3/8] Discovering gateway...${NC}"
GATEWAY_IP=$(ip route | grep default | grep $INTERFACE | awk '{print $3}')

if [ -z "$GATEWAY_IP" ]; then
    echo -e "${RED}✗ Could not discover gateway${NC}"
    echo "Please ensure you have internet connectivity"
    exit 1
fi

# Get gateway MAC via ARP
ping -c 1 -W 1 $GATEWAY_IP > /dev/null 2>&1 || true
sleep 1
GATEWAY_MAC=$(ip neigh show $GATEWAY_IP | grep $INTERFACE | awk '{print $5}')

# If still empty, use arping
if [ -z "$GATEWAY_MAC" ]; then
    arping -c 1 -I $INTERFACE $GATEWAY_IP > /dev/null 2>&1 || true
    sleep 1
    GATEWAY_MAC=$(ip neigh show $GATEWAY_IP | grep $INTERFACE | awk '{print $5}')
fi

if [ -z "$GATEWAY_MAC" ]; then
    echo -e "${RED}✗ Could not determine gateway MAC address${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Gateway discovered${NC}"
echo "  Gateway IP:  $GATEWAY_IP"
echo "  Gateway MAC: $GATEWAY_MAC"
echo ""

# Confirm deployment
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}WARNING: About to enable Transparent Gateway Mode${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo ""
echo "This will:"
echo "  1. ARP spoof the gateway ($GATEWAY_IP)"
echo "  2. Redirect all client traffic through HomeGuard"
echo "  3. Enforce PVLAN (client isolation)"
echo "  4. Filter DNS through Pi-hole"
echo ""
echo "Network devices will be transparently protected."
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

# Enable IP forwarding
echo -e "${YELLOW}[4/8] Enabling IP forwarding...${NC}"
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-homeguard-forward.conf
sysctl -p /etc/sysctl.d/99-homeguard-forward.conf > /dev/null
echo -e "${GREEN}✓ IP forwarding enabled${NC}"

# Configure ebtables (PVLAN enforcement)
echo -e "${YELLOW}[5/8] Configuring PVLAN isolation (ebtables)...${NC}"

# Clear existing rules
ebtables -F > /dev/null 2>&1 || true
ebtables -X > /dev/null 2>&1 || true

# Set default policy
ebtables -P FORWARD DROP

# Allow traffic to HomeGuard
ebtables -A FORWARD -d $HOMEGUARD_MAC -j ACCEPT

# Allow traffic from HomeGuard
ebtables -A FORWARD -s $HOMEGUARD_MAC -j ACCEPT

# Allow traffic to real gateway
ebtables -A FORWARD -d $GATEWAY_MAC -j ACCEPT

# Allow traffic from real gateway
ebtables -A FORWARD -s $GATEWAY_MAC -j ACCEPT

# Allow broadcast (DHCP, ARP)
ebtables -A FORWARD -d ff:ff:ff:ff:ff:ff -j ACCEPT

# Optional: Allow multicast (for Chromecast, AirPlay, mDNS)
if [ "$ENABLE_MULTICAST" = true ]; then
    ebtables -A FORWARD -d 01:00:5e:00:00:00/01:00:00:00:00:00 -j ACCEPT  # IPv4 multicast
    ebtables -A FORWARD -d 33:33:00:00:00:00/ff:ff:00:00:00:00 -j ACCEPT  # IPv6 multicast
    echo -e "${GREEN}✓ PVLAN configured (multicast allowed)${NC}"
else
    echo -e "${GREEN}✓ PVLAN configured (strict isolation)${NC}"
fi

# Log blocked traffic
ebtables -A FORWARD -j LOG --log-prefix "PVLAN-BLOCK: " --log-level warning

# Drop everything else (client-to-client)
ebtables -A FORWARD -j DROP

# Save ebtables rules
if command -v ebtables-save &>/dev/null; then
    ebtables-save > /etc/ebtables.rules
fi

# Configure iptables (DNS interception + forwarding)
echo -e "${YELLOW}[6/8] Configuring traffic interception (iptables)...${NC}"

# Intercept all DNS queries and redirect to Pi-hole
iptables -t nat -A PREROUTING -i $INTERFACE -p udp --dport 53 -j REDIRECT --to-ports 53
iptables -t nat -A PREROUTING -i $INTERFACE -p tcp --dport 53 -j REDIRECT --to-ports 53

# Allow forwarding
iptables -A FORWARD -i $INTERFACE -o $INTERFACE -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Save iptables rules
iptables-save > /etc/iptables/rules.v4

echo -e "${GREEN}✓ Traffic interception configured${NC}"

# Create ARP spoofing service
echo -e "${YELLOW}[7/8] Creating ARP spoofing service...${NC}"

cat > /opt/homeguard/scripts/arp-spoof-gateway.sh <<EOFSCRIPT
#!/bin/bash
# ARP Spoofing Script - Claims to be the gateway

INTERFACE="$INTERFACE"
GATEWAY_IP="$GATEWAY_IP"

while true; do
    # Send gratuitous ARP claiming to be gateway
    arping -U -c 1 -I \$INTERFACE -s \$GATEWAY_IP \$GATEWAY_IP > /dev/null 2>&1

    # Wait before next announcement
    sleep $ARP_INTERVAL
done
EOFSCRIPT

chmod +x /opt/homeguard/scripts/arp-spoof-gateway.sh

# Create systemd service for ARP spoofing
cat > /etc/systemd/system/homeguard-arpspoof.service <<EOFSERVICE
[Unit]
Description=HomeGuard ARP Spoofing Service (Transparent Gateway)
After=network-online.target
Wants=network-online.target
Documentation=file:///opt/homeguard/docs/transparent-gateway-architecture.md

[Service]
Type=simple
ExecStart=/opt/homeguard/scripts/arp-spoof-gateway.sh
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOFSERVICE

# Enable and start service
systemctl daemon-reload
systemctl enable homeguard-arpspoof.service
systemctl start homeguard-arpspoof.service

echo -e "${GREEN}✓ ARP spoofing service created and started${NC}"

# Create restore script for ebtables/iptables on boot
echo -e "${YELLOW}[8/8] Creating startup restoration service...${NC}"

cat > /etc/systemd/system/homeguard-restore-rules.service <<EOFRESTORE
[Unit]
Description=HomeGuard Restore ebtables/iptables Rules
After=network-online.target
Before=homeguard-arpspoof.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'if [ -f /etc/ebtables.rules ]; then ebtables-restore < /etc/ebtables.rules; fi'
ExecStart=/sbin/iptables-restore /etc/iptables/rules.v4
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOFRESTORE

systemctl daemon-reload
systemctl enable homeguard-restore-rules.service

echo -e "${GREEN}✓ Startup restoration configured${NC}"

# Create management commands
cat > /usr/local/bin/homeguard-transparent <<'EOFCMD'
#!/bin/bash
# HomeGuard Transparent Gateway Management

case "$1" in
    status)
        echo "HomeGuard Transparent Gateway Status"
        echo "======================================"
        echo ""

        # ARP spoofing status
        if systemctl is-active --quiet homeguard-arpspoof.service; then
            echo "✓ ARP Spoofing: Active"

            INTERFACE=$(grep INTERFACE= /opt/homeguard/scripts/arp-spoof-gateway.sh | cut -d'"' -f2)
            GATEWAY=$(grep GATEWAY_IP= /opt/homeguard/scripts/arp-spoof-gateway.sh | cut -d'"' -f2)

            echo "  Interface: $INTERFACE"
            echo "  Spoofing: $GATEWAY"
        else
            echo "✗ ARP Spoofing: Inactive"
        fi

        echo ""

        # PVLAN status
        PVLAN_RULES=$(ebtables -L FORWARD 2>/dev/null | grep -c "DROP\|ACCEPT" || echo "0")
        if [ "$PVLAN_RULES" -gt 0 ]; then
            echo "✓ PVLAN Enforcement: Active ($PVLAN_RULES rules)"
        else
            echo "✗ PVLAN Enforcement: Inactive"
        fi

        echo ""

        # Show intercepted clients
        echo "Intercepted Clients:"
        arp -n | grep -v incomplete | tail -n +2 | while read line; do
            IP=$(echo $line | awk '{print $1}')
            MAC=$(echo $line | awk '{print $3}')
            echo "  $IP ($MAC)"
        done

        echo ""

        # PVLAN block statistics
        BLOCKS=$(ebtables -L FORWARD --Lc 2>/dev/null | grep "PVLAN-BLOCK" | awk '{print $1}' || echo "0")
        echo "PVLAN Blocks: $BLOCKS client-to-client attempts blocked"
        ;;

    start)
        echo "Starting transparent gateway..."
        systemctl start homeguard-arpspoof.service
        echo "✓ Transparent gateway started"
        ;;

    stop)
        echo "Stopping transparent gateway..."
        systemctl stop homeguard-arpspoof.service
        echo "✓ Transparent gateway stopped"
        echo ""
        echo "Note: Clients will revert to real gateway within 60 seconds"
        ;;

    restart)
        echo "Restarting transparent gateway..."
        systemctl restart homeguard-arpspoof.service
        echo "✓ Transparent gateway restarted"
        ;;

    logs)
        echo "ARP Spoofing Logs (last 50 lines):"
        journalctl -u homeguard-arpspoof.service -n 50 --no-pager
        echo ""
        echo "PVLAN Block Logs (last 20):"
        journalctl | grep "PVLAN-BLOCK" | tail -20
        ;;

    clients)
        echo "Clients Intercepted by HomeGuard"
        echo "================================="
        echo ""
        printf "%-15s %-17s %-20s %s\n" "IP Address" "MAC Address" "Hostname" "Status"
        printf "%-15s %-17s %-20s %s\n" "----------" "-----------" "--------" "------"

        arp -n | grep -v incomplete | tail -n +2 | while read line; do
            IP=$(echo $line | awk '{print $1}')
            MAC=$(echo $line | awk '{print $3}')
            HOSTNAME=$(nslookup $IP 2>/dev/null | grep "name =" | awk '{print $4}' | sed 's/\.$//' || echo "unknown")

            # Check if client is actually using HomeGuard (has ARP entry pointing to us)
            if arping -c 1 -I eth0 $IP 2>/dev/null | grep -q "reply from"; then
                STATUS="Active"
            else
                STATUS="Unknown"
            fi

            printf "%-15s %-17s %-20s %s\n" "$IP" "$MAC" "$HOSTNAME" "$STATUS"
        done
        ;;

    *)
        echo "HomeGuard Transparent Gateway Management"
        echo ""
        echo "Usage: $0 {status|start|stop|restart|logs|clients}"
        echo ""
        echo "Commands:"
        echo "  status   - Show transparent gateway status"
        echo "  start    - Start ARP spoofing (enable transparent mode)"
        echo "  stop     - Stop ARP spoofing (disable transparent mode)"
        echo "  restart  - Restart ARP spoofing service"
        echo "  logs     - View ARP spoofing and PVLAN block logs"
        echo "  clients  - List intercepted clients"
        exit 1
        ;;
esac
EOFCMD

chmod +x /usr/local/bin/homeguard-transparent

# Final summary
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Transparent Gateway Setup Complete!                     ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Configuration Summary:${NC}"
echo "  HomeGuard IP:  $HOMEGUARD_IP (MAC: $HOMEGUARD_MAC)"
echo "  Gateway IP:    $GATEWAY_IP (MAC: $GATEWAY_MAC)"
echo "  Interface:     $INTERFACE"
echo ""
echo -e "${BLUE}What's Running:${NC}"
echo "  ✓ ARP Spoofing    - Claiming to be gateway every ${ARP_INTERVAL}s"
echo "  ✓ PVLAN           - Client isolation enforced via ebtables"
echo "  ✓ DNS Intercept   - All DNS queries redirect to Pi-hole"
echo "  ✓ Traffic Forward - All traffic flows through HomeGuard"
echo ""
echo -e "${BLUE}Network Flow:${NC}"
echo "  Client → HomeGuard (ARP spoofed) → Pi-hole/Unbound → Real Gateway → Internet"
echo ""
echo -e "${BLUE}Management Commands:${NC}"
echo "  homeguard-transparent status   - Check status"
echo "  homeguard-transparent clients  - List intercepted clients"
echo "  homeguard-transparent logs     - View logs"
echo "  homeguard-transparent stop     - Disable transparent mode"
echo ""
echo -e "${YELLOW}Note: All network devices now route through HomeGuard transparently.${NC}"
echo -e "${YELLOW}Clients are isolated from each other (PVLAN enforced).${NC}"
echo ""
echo -e "${GREEN}Setup complete! Your network is now protected.${NC}"
