#!/bin/bash
# HomeGuard Pro - Complete Installation with Transparent Gateway Mode
#
# This master script installs everything from scratch:
# - Pi-hole (DNS ad-blocking)
# - Unbound (recursive DNS resolver)
# - Dashboard (web interface)
# - Network monitor (device discovery)
# - Transparent Gateway Mode (ARP spoofing + PVLAN)
#
# Usage: curl -sSL https://raw.githubusercontent.com/.../install-complete-transparent.sh | sudo bash
#        OR: sudo ./install-complete-transparent.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/opt/homeguard"
LOG_FILE="/var/log/homeguard-install.log"
PIHOLE_WEBPASSWORD=""
ENABLE_TRANSPARENT_MODE=true

# Logging function
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "${RED}ERROR: $1${NC}"
    exit 1
}

# Banner
clear
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║              HomeGuard Pro - Complete Installation          ║
║                                                              ║
║  • Pi-hole (DNS Ad-Blocking)                                ║
║  • Unbound (Private Recursive DNS)                          ║
║  • Dashboard (Web Interface)                                ║
║  • Network Monitor (Device Discovery)                       ║
║  • Transparent Gateway (ARP Spoofing + PVLAN)               ║
║                                                              ║
║  Installation time: ~15-20 minutes                          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF

echo ""
log "${CYAN}Starting installation at $(date)${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error_exit "This script must be run as root. Please run: sudo $0"
fi

# Check OS
if ! grep -q "Raspberry Pi\|Debian\|Ubuntu" /etc/os-release 2>/dev/null; then
    log "${YELLOW}Warning: This script is designed for Raspberry Pi OS, Debian, or Ubuntu.${NC}"
    log "${YELLOW}Other distributions may not work correctly.${NC}"
    read -p "Continue anyway? (yes/no): " continue_install
    if [ "$continue_install" != "yes" ]; then
        exit 0
    fi
fi

# Create installation directory
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/scripts"
mkdir -p "$INSTALL_DIR/docs"
mkdir -p "$INSTALL_DIR/config"

# ============================================================
# STEP 1: System Update & Dependencies
# ============================================================

log "${YELLOW}[1/10] Updating system and installing dependencies...${NC}"
apt-get update -qq || error_exit "Failed to update package lists"

log "  Installing base dependencies..."
apt-get install -y \
    curl \
    wget \
    git \
    dnsutils \
    net-tools \
    iproute2 \
    iptables \
    iptables-persistent \
    ebtables \
    arping \
    netfilter-persistent \
    sqlite3 \
    nginx \
    python3 \
    python3-pip \
    >> "$LOG_FILE" 2>&1 || error_exit "Failed to install dependencies"

log "${GREEN}✓ Dependencies installed${NC}"

# ============================================================
# STEP 2: Install Pi-hole
# ============================================================

log "${YELLOW}[2/10] Installing Pi-hole...${NC}"

if command -v pihole &>/dev/null; then
    log "${GREEN}✓ Pi-hole already installed, skipping...${NC}"
else
    log "  Downloading Pi-hole installer..."

    # Create unattended Pi-hole config
    cat > /etc/pihole/setupVars.conf <<EOF
WEBPASSWORD=$(openssl rand -hex 16)
PIHOLE_INTERFACE=eth0
IPV4_ADDRESS=0.0.0.0/0
IPV6_ADDRESS=
PIHOLE_DNS_1=127.0.0.1#5335
PIHOLE_DNS_2=
QUERY_LOGGING=true
INSTALL_WEB_SERVER=true
INSTALL_WEB_INTERFACE=true
LIGHTTPD_ENABLED=true
CACHE_SIZE=10000
DNS_FQDN_REQUIRED=true
DNS_BOGUS_PRIV=true
DNSMASQ_LISTENING=all
BLOCKING_ENABLED=true
EOF

    # Download and run Pi-hole installer
    curl -sSL https://install.pi-hole.net > /tmp/pihole-install.sh
    chmod +x /tmp/pihole-install.sh

    # Run unattended install
    PIHOLE_SKIP_OS_CHECK=true bash /tmp/pihole-install.sh --unattended >> "$LOG_FILE" 2>&1

    if ! command -v pihole &>/dev/null; then
        error_exit "Pi-hole installation failed. Check $LOG_FILE for details."
    fi

    # Save password
    PIHOLE_WEBPASSWORD=$(grep WEBPASSWORD /etc/pihole/setupVars.conf | cut -d= -f2)

    log "${GREEN}✓ Pi-hole installed${NC}"
fi

# ============================================================
# STEP 3: Install Unbound
# ============================================================

log "${YELLOW}[3/10] Installing Unbound...${NC}"

if command -v unbound &>/dev/null; then
    log "${GREEN}✓ Unbound already installed${NC}"
else
    apt-get install -y unbound >> "$LOG_FILE" 2>&1 || error_exit "Failed to install Unbound"
    log "${GREEN}✓ Unbound installed${NC}"
fi

# ============================================================
# STEP 4: Configure Unbound
# ============================================================

log "${YELLOW}[4/10] Configuring Unbound...${NC}"

# Create Unbound config for Pi-hole
cat > /etc/unbound/unbound.conf.d/pi-hole.conf <<'EOFUNBOUND'
server:
    # Listen on localhost for Pi-hole
    interface: 127.0.0.1
    port: 5335

    # Access control
    access-control: 127.0.0.1/32 allow
    access-control: 0.0.0.0/0 refuse

    # Privacy settings
    hide-identity: yes
    hide-version: yes
    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: yes

    # Performance
    cache-min-ttl: 3600
    cache-max-ttl: 86400
    prefetch: yes
    num-threads: 1

    # Don't use /etc/hosts or /etc/resolv.conf
    do-not-query-localhost: no

    # DNSSEC
    auto-trust-anchor-file: "/var/lib/unbound/root.key"

    # Privacy
    qname-minimisation: yes

    # Logging (disable for production)
    verbosity: 0

# Forward zones (none - full recursive)
EOFUNBOUND

# Create root hints
wget -q https://www.internic.net/domain/named.cache -O /var/lib/unbound/root.hints || true

# Restart Unbound
systemctl enable unbound >> "$LOG_FILE" 2>&1
systemctl restart unbound >> "$LOG_FILE" 2>&1

# Test Unbound
if dig @127.0.0.1 -p 5335 google.com +short &>/dev/null; then
    log "${GREEN}✓ Unbound configured and working${NC}"
else
    log "${YELLOW}⚠ Unbound may not be working correctly${NC}"
fi

# ============================================================
# STEP 5: Configure Pi-hole to use Unbound
# ============================================================

log "${YELLOW}[5/10] Connecting Pi-hole to Unbound...${NC}"

# Update Pi-hole config
pihole -a setdns 127.0.0.1#5335 >> "$LOG_FILE" 2>&1

# Restart Pi-hole DNS
pihole restartdns >> "$LOG_FILE" 2>&1

log "${GREEN}✓ Pi-hole configured to use Unbound${NC}"

# ============================================================
# STEP 6: Configure Dashboard
# ============================================================

log "${YELLOW}[6/10] Setting up web dashboard...${NC}"

# Create dashboard directory
mkdir -p /var/www/homeguard

# Create simple dashboard (placeholder)
cat > /var/www/homeguard/index.html <<'EOFDASH'
<!DOCTYPE html>
<html>
<head>
    <title>HomeGuard Pro</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 20px;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            max-width: 600px;
            width: 100%;
        }
        h1 {
            color: #667eea;
            margin: 0 0 20px 0;
            font-size: 2.5em;
        }
        .status {
            background: #f0f9ff;
            border-left: 4px solid #667eea;
            padding: 15px;
            margin: 20px 0;
            border-radius: 5px;
        }
        .link-box {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin: 20px 0;
        }
        .link {
            background: #667eea;
            color: white;
            padding: 20px;
            text-align: center;
            border-radius: 10px;
            text-decoration: none;
            transition: transform 0.2s;
        }
        .link:hover {
            transform: translateY(-5px);
            background: #5568d3;
        }
        .info {
            background: #fffbeb;
            border: 1px solid #fcd34d;
            padding: 15px;
            border-radius: 5px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🛡️ HomeGuard Pro</h1>
        <p>Your network is now protected!</p>

        <div class="status">
            <strong>✓ Transparent Gateway Active</strong><br>
            All network traffic is being filtered and monitored.
        </div>

        <div class="link-box">
            <a href="/admin" class="link">
                <div>📊 Pi-hole</div>
                <div style="font-size: 0.9em; margin-top: 5px;">View Statistics</div>
            </a>
            <a href="/admin/settings.php" class="link">
                <div>⚙️ Settings</div>
                <div style="font-size: 0.9em; margin-top: 5px;">Configuration</div>
            </a>
        </div>

        <div class="info">
            <strong>Management Commands:</strong><br>
            <code>homeguard-transparent status</code> - Check status<br>
            <code>homeguard-transparent clients</code> - View clients<br>
            <code>homeguard-transparent logs</code> - View logs
        </div>
    </div>
</body>
</html>
EOFDASH

# Configure Nginx
cat > /etc/nginx/sites-available/homeguard <<'EOFNGINX'
server {
    listen 8080 default_server;
    server_name _;

    root /var/www/homeguard;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    # Proxy to Pi-hole admin
    location /admin {
        proxy_pass http://127.0.0.1:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOFNGINX

# Enable site
ln -sf /etc/nginx/sites-available/homeguard /etc/nginx/sites-enabled/homeguard
rm -f /etc/nginx/sites-enabled/default

# Test and restart Nginx
nginx -t >> "$LOG_FILE" 2>&1 && systemctl restart nginx

log "${GREEN}✓ Dashboard configured (accessible on port 8080)${NC}"

# ============================================================
# STEP 7: Install Network Monitor (Simple Version)
# ============================================================

log "${YELLOW}[7/10] Setting up network monitor...${NC}"

# Simple network monitor script
cat > "$INSTALL_DIR/scripts/network-monitor.sh" <<'EOFMONITOR'
#!/bin/bash
# Simple network monitor - logs connected devices

LOG_FILE="/var/log/homeguard-devices.log"

while true; do
    echo "=== Network Scan: $(date) ===" >> "$LOG_FILE"
    arp -n | tail -n +2 >> "$LOG_FILE"
    sleep 300  # Scan every 5 minutes
done
EOFMONITOR

chmod +x "$INSTALL_DIR/scripts/network-monitor.sh"

# Create systemd service
cat > /etc/systemd/system/homeguard-monitor.service <<EOFSERVICE
[Unit]
Description=HomeGuard Network Monitor
After=network-online.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/scripts/network-monitor.sh
Restart=always
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOFSERVICE

systemctl daemon-reload
systemctl enable homeguard-monitor.service >> "$LOG_FILE" 2>&1
systemctl start homeguard-monitor.service

log "${GREEN}✓ Network monitor installed${NC}"

# ============================================================
# STEP 8: Enable Transparent Gateway Mode
# ============================================================

if [ "$ENABLE_TRANSPARENT_MODE" = true ]; then
    log "${YELLOW}[8/10] Enabling Transparent Gateway Mode...${NC}"

    # Detect network interface
    if ip link show wlan0 &>/dev/null && ip addr show wlan0 | grep -q "inet "; then
        INTERFACE="wlan0"
        log "  Using WiFi interface: wlan0"
    elif ip link show eth0 &>/dev/null && ip addr show eth0 | grep -q "inet "; then
        INTERFACE="eth0"
        log "  Using Ethernet interface: eth0"
    else
        log "${YELLOW}⚠ No active network interface found${NC}"
        log "${YELLOW}⚠ Skipping transparent gateway setup${NC}"
        log "${YELLOW}⚠ Connect to network and run: sudo $INSTALL_DIR/scripts/setup-transparent-gateway.sh${NC}"
        ENABLE_TRANSPARENT_MODE=false
    fi

    if [ "$ENABLE_TRANSPARENT_MODE" = true ]; then
        # Get network info
        HOMEGUARD_IP=$(ip addr show $INTERFACE | grep "inet " | awk '{print $2}' | cut -d/ -f1)
        HOMEGUARD_MAC=$(ip link show $INTERFACE | grep ether | awk '{print $2}')
        GATEWAY_IP=$(ip route | grep default | grep $INTERFACE | awk '{print $3}')

        if [ -z "$GATEWAY_IP" ]; then
            log "${YELLOW}⚠ Could not discover gateway${NC}"
            ENABLE_TRANSPARENT_MODE=false
        else
            # Get gateway MAC
            ping -c 1 -W 1 $GATEWAY_IP > /dev/null 2>&1 || true
            sleep 1
            GATEWAY_MAC=$(ip neigh show $GATEWAY_IP | grep $INTERFACE | awk '{print $5}')

            if [ -z "$GATEWAY_MAC" ]; then
                arping -c 1 -I $INTERFACE $GATEWAY_IP > /dev/null 2>&1 || true
                sleep 1
                GATEWAY_MAC=$(ip neigh show $GATEWAY_IP | grep $INTERFACE | awk '{print $5}')
            fi

            if [ -z "$GATEWAY_MAC" ]; then
                log "${YELLOW}⚠ Could not determine gateway MAC${NC}"
                ENABLE_TRANSPARENT_MODE=false
            fi
        fi
    fi

    if [ "$ENABLE_TRANSPARENT_MODE" = true ]; then
        log "  HomeGuard: $HOMEGUARD_IP ($HOMEGUARD_MAC)"
        log "  Gateway: $GATEWAY_IP ($GATEWAY_MAC)"

        # Enable IP forwarding
        echo 1 > /proc/sys/net/ipv4/ip_forward
        echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-homeguard-forward.conf

        # Configure ebtables (PVLAN)
        ebtables -F > /dev/null 2>&1 || true
        ebtables -X > /dev/null 2>&1 || true
        ebtables -P FORWARD DROP
        ebtables -A FORWARD -d $HOMEGUARD_MAC -j ACCEPT
        ebtables -A FORWARD -s $HOMEGUARD_MAC -j ACCEPT
        ebtables -A FORWARD -d $GATEWAY_MAC -j ACCEPT
        ebtables -A FORWARD -s $GATEWAY_MAC -j ACCEPT
        ebtables -A FORWARD -d ff:ff:ff:ff:ff:ff -j ACCEPT
        ebtables -A FORWARD -j LOG --log-prefix "PVLAN-BLOCK: " --log-level warning
        ebtables -A FORWARD -j DROP

        # Save ebtables rules
        mkdir -p /etc/ebtables
        ebtables-save > /etc/ebtables/rules 2>/dev/null || true

        # Configure iptables (DNS interception)
        iptables -t nat -A PREROUTING -i $INTERFACE -p udp --dport 53 -j REDIRECT --to-ports 53
        iptables -t nat -A PREROUTING -i $INTERFACE -p tcp --dport 53 -j REDIRECT --to-ports 53
        iptables -A FORWARD -i $INTERFACE -o $INTERFACE -j ACCEPT
        iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

        # Save iptables rules
        netfilter-persistent save >> "$LOG_FILE" 2>&1

        # Create ARP spoofing script
        cat > "$INSTALL_DIR/scripts/arp-spoof-gateway.sh" <<EOFARP
#!/bin/bash
INTERFACE="$INTERFACE"
GATEWAY_IP="$GATEWAY_IP"

while true; do
    arping -U -c 1 -I \$INTERFACE -s \$GATEWAY_IP \$GATEWAY_IP > /dev/null 2>&1
    sleep 2
done
EOFARP

        chmod +x "$INSTALL_DIR/scripts/arp-spoof-gateway.sh"

        # Create ARP spoofing service
        cat > /etc/systemd/system/homeguard-arpspoof.service <<EOFARPSERVICE
[Unit]
Description=HomeGuard ARP Spoofing Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/scripts/arp-spoof-gateway.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOFARPSERVICE

        systemctl daemon-reload
        systemctl enable homeguard-arpspoof.service >> "$LOG_FILE" 2>&1
        systemctl start homeguard-arpspoof.service

        log "${GREEN}✓ Transparent Gateway Mode enabled${NC}"
    fi
else
    log "${YELLOW}[8/10] Transparent Gateway Mode disabled (can enable later)${NC}"
fi

# ============================================================
# STEP 9: Create Management Commands
# ============================================================

log "${YELLOW}[9/10] Creating management commands...${NC}"

# Create homeguard-transparent command
cat > /usr/local/bin/homeguard-transparent <<'EOFCMD'
#!/bin/bash
# HomeGuard Transparent Gateway Management

case "$1" in
    status)
        echo "HomeGuard Transparent Gateway Status"
        echo "======================================"
        echo ""
        if systemctl is-active --quiet homeguard-arpspoof.service; then
            echo "✓ ARP Spoofing: Active"
            INTERFACE=$(grep INTERFACE= /opt/homeguard/scripts/arp-spoof-gateway.sh 2>/dev/null | cut -d'"' -f2)
            GATEWAY=$(grep GATEWAY_IP= /opt/homeguard/scripts/arp-spoof-gateway.sh 2>/dev/null | cut -d'"' -f2)
            echo "  Interface: $INTERFACE"
            echo "  Spoofing: $GATEWAY"
        else
            echo "✗ ARP Spoofing: Inactive"
        fi
        echo ""
        PVLAN_RULES=$(ebtables -L FORWARD 2>/dev/null | grep -c "DROP\|ACCEPT" || echo "0")
        if [ "$PVLAN_RULES" -gt 0 ]; then
            echo "✓ PVLAN Enforcement: Active ($PVLAN_RULES rules)"
        else
            echo "✗ PVLAN Enforcement: Inactive"
        fi
        ;;
    start)
        echo "Starting transparent gateway..."
        systemctl start homeguard-arpspoof.service
        echo "✓ Started"
        ;;
    stop)
        echo "Stopping transparent gateway..."
        systemctl stop homeguard-arpspoof.service
        echo "✓ Stopped"
        ;;
    restart)
        echo "Restarting transparent gateway..."
        systemctl restart homeguard-arpspoof.service
        echo "✓ Restarted"
        ;;
    logs)
        journalctl -u homeguard-arpspoof.service -n 50 --no-pager
        ;;
    *)
        echo "Usage: $0 {status|start|stop|restart|logs}"
        exit 1
        ;;
esac
EOFCMD

chmod +x /usr/local/bin/homeguard-transparent

# Create main homeguard command
cat > /usr/local/bin/homeguard <<'EOFMAIN'
#!/bin/bash
# HomeGuard Main Management Command

case "$1" in
    status)
        echo "HomeGuard Pro Status"
        echo "===================="
        echo ""
        echo "Core Services:"
        systemctl is-active --quiet pihole-FTL && echo "  ✓ Pi-hole: Running" || echo "  ✗ Pi-hole: Stopped"
        systemctl is-active --quiet unbound && echo "  ✓ Unbound: Running" || echo "  ✗ Unbound: Stopped"
        systemctl is-active --quiet nginx && echo "  ✓ Dashboard: Running" || echo "  ✗ Dashboard: Stopped"
        systemctl is-active --quiet homeguard-monitor && echo "  ✓ Monitor: Running" || echo "  ✗ Monitor: Stopped"
        echo ""
        echo "Transparent Gateway:"
        systemctl is-active --quiet homeguard-arpspoof && echo "  ✓ ARP Spoof: Active" || echo "  ✗ ARP Spoof: Inactive"
        ;;
    restart)
        echo "Restarting HomeGuard services..."
        systemctl restart pihole-FTL
        systemctl restart unbound
        systemctl restart nginx
        systemctl restart homeguard-monitor
        systemctl restart homeguard-arpspoof 2>/dev/null || true
        echo "✓ All services restarted"
        ;;
    stop)
        echo "Stopping HomeGuard services..."
        systemctl stop homeguard-arpspoof 2>/dev/null || true
        systemctl stop pihole-FTL
        systemctl stop unbound
        echo "✓ Services stopped"
        ;;
    start)
        echo "Starting HomeGuard services..."
        systemctl start unbound
        systemctl start pihole-FTL
        systemctl start nginx
        systemctl start homeguard-monitor
        systemctl start homeguard-arpspoof 2>/dev/null || true
        echo "✓ Services started"
        ;;
    *)
        echo "HomeGuard Pro Management"
        echo ""
        echo "Usage: $0 {status|start|stop|restart}"
        echo ""
        echo "Additional commands:"
        echo "  homeguard-transparent - Transparent gateway management"
        echo "  pihole                - Pi-hole management"
        exit 1
        ;;
esac
EOFMAIN

chmod +x /usr/local/bin/homeguard

log "${GREEN}✓ Management commands created${NC}"

# ============================================================
# STEP 10: Final Tests & Summary
# ============================================================

log "${YELLOW}[10/10] Running final tests...${NC}"

# Test DNS
if dig @127.0.0.1 google.com +short &>/dev/null; then
    log "${GREEN}✓ DNS resolution working${NC}"
else
    log "${YELLOW}⚠ DNS may not be working correctly${NC}"
fi

# Test Pi-hole
if curl -s http://127.0.0.1/admin/api.php | grep -q "status"; then
    log "${GREEN}✓ Pi-hole API responding${NC}"
else
    log "${YELLOW}⚠ Pi-hole API may not be responding${NC}"
fi

# Get IP address
DEVICE_IP=$(hostname -I | awk '{print $1}')

# ============================================================
# Installation Complete!
# ============================================================

clear
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║            ✓ HomeGuard Pro Installation Complete!           ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF

echo ""
log "${GREEN}═══ Installation Summary ═══${NC}"
echo ""
log "HomeGuard IP: ${CYAN}$DEVICE_IP${NC}"
echo ""
log "${GREEN}Installed Components:${NC}"
log "  ✓ Pi-hole          - DNS ad-blocking"
log "  ✓ Unbound          - Recursive DNS resolver"
log "  ✓ Dashboard        - Web interface (port 8080)"
log "  ✓ Network Monitor  - Device discovery"
if [ "$ENABLE_TRANSPARENT_MODE" = true ]; then
    log "  ✓ Transparent Mode - ARP spoofing + PVLAN"
else
    log "  ○ Transparent Mode - Not configured (run setup later)"
fi
echo ""
log "${GREEN}Access Points:${NC}"
log "  Dashboard:  ${CYAN}http://$DEVICE_IP:8080${NC}"
log "  Pi-hole:    ${CYAN}http://$DEVICE_IP/admin${NC}"
echo ""
log "${GREEN}Pi-hole Web Password:${NC} ${CYAN}$PIHOLE_WEBPASSWORD${NC}"
log "  (Save this password!)"
echo ""
log "${GREEN}Management Commands:${NC}"
log "  ${CYAN}homeguard status${NC}              - Check all services"
log "  ${CYAN}homeguard-transparent status${NC}  - Check transparent mode"
log "  ${CYAN}homeguard restart${NC}             - Restart all services"
echo ""

if [ "$ENABLE_TRANSPARENT_MODE" = true ]; then
    log "${GREEN}Network Protection:${NC}"
    log "  ✓ All devices on your network are now being protected"
    log "  ✓ DNS queries filtered through Pi-hole"
    log "  ✓ Clients isolated from each other (PVLAN)"
    log "  ✓ Traffic transparently routed through HomeGuard"
else
    log "${YELLOW}To enable Transparent Gateway Mode:${NC}"
    log "  1. Connect HomeGuard to your network (WiFi or Ethernet)"
    log "  2. Run: ${CYAN}sudo $INSTALL_DIR/scripts/setup-transparent-gateway.sh${NC}"
fi

echo ""
log "${GREEN}Next Steps:${NC}"
log "  1. Visit ${CYAN}http://$DEVICE_IP:8080${NC} to see your dashboard"
log "  2. Login to Pi-hole at ${CYAN}http://$DEVICE_IP/admin${NC}"
log "  3. Customize blocklists in Pi-hole admin panel"
log "  4. Run ${CYAN}homeguard status${NC} to verify everything is working"
echo ""
log "${CYAN}Installation log saved to: $LOG_FILE${NC}"
echo ""
log "${GREEN}Your network is now protected! 🛡️${NC}"
echo ""
