#!/bin/bash
# HomeGuard Pro - Native Installation (No Docker)
# Installs all services directly on the system

set -e

echo "=================================="
echo "   HomeGuard Pro Installation"
echo "   Native (Docker-Free) Version"
echo "=================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  This script must be run as root (use sudo)"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo "❌ Cannot detect OS"
    exit 1
fi

echo "✓ Detected OS: $OS $VERSION"

# Installation directory
INSTALL_DIR="/opt/homeguard"
DATA_DIR="$INSTALL_DIR/data"
WEB_DIR="/var/www/homeguard"

echo ""
echo "📦 Installing system dependencies..."

if [ "$OS" = "raspbian" ] || [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
    apt-get update -qq
    apt-get install -y \
        curl \
        git \
        python3 \
        python3-pip \
        nginx \
        sqlite3 \
        arp-scan \
        net-tools \
        dnsutils \
        unbound \
        ca-certificates
else
    echo "⚠️  Unsupported OS. Manual installation required."
    exit 1
fi

echo "✓ System dependencies installed"

# Create directories
echo ""
echo "📁 Creating directory structure..."
mkdir -p $INSTALL_DIR/{scripts,configs,logs}
mkdir -p $DATA_DIR/{pihole,netmonitor}
mkdir -p $WEB_DIR

echo "✓ Directories created"

# Install Pi-hole
echo ""
echo "🛡️  Installing Pi-hole..."
echo ""
echo "IMPORTANT: During Pi-hole installation:"
echo "  1. Choose 'eth0' as the network interface"
echo "  2. Select upstream DNS: Custom -> 127.0.0.1#5335 (Unbound)"
echo "  3. Install web interface: YES"
echo "  4. Install web server: YES (lighttpd)"
echo ""
read -p "Press Enter to continue with Pi-hole installation..."

# Check if Pi-hole is already installed
if command -v pihole &> /dev/null; then
    echo "✓ Pi-hole already installed"
else
    curl -sSL https://install.pi-hole.net | bash
fi

# Configure Unbound
echo ""
echo "🔒 Configuring Unbound (Recursive DNS)..."

# Backup original config
if [ -f /etc/unbound/unbound.conf ]; then
    cp /etc/unbound/unbound.conf /etc/unbound/unbound.conf.backup
fi

# Create Pi-hole optimized Unbound config
cat > /etc/unbound/unbound.conf.d/pi-hole.conf <<'EOF'
server:
    # Performance
    verbosity: 0
    interface: 127.0.0.1
    port: 5335
    do-ip4: yes
    do-ip6: no
    do-udp: yes
    do-tcp: yes

    # Access control
    access-control: 127.0.0.1/32 allow
    access-control: 0.0.0.0/0 refuse

    # Privacy
    hide-identity: yes
    hide-version: yes
    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: yes

    # Performance tuning
    cache-min-ttl: 3600
    cache-max-ttl: 86400
    prefetch: yes
    prefetch-key: yes

    # Threading
    num-threads: 2
    msg-cache-slabs: 4
    rrset-cache-slabs: 4
    infra-cache-slabs: 4
    key-cache-slabs: 4

    # Memory
    rrset-cache-size: 100m
    msg-cache-size: 50m
    so-rcvbuf: 1m

    # Hardening
    harden-below-nxdomain: yes
    harden-referral-path: yes

    # Privacy
    qname-minimisation: yes

    # Root hints (for recursive resolution)
    root-hints: "/var/lib/unbound/root.hints"

# Forward zones (optional - remove if doing full recursion)
# forward-zone:
#     name: "."
#     forward-addr: 1.1.1.1
#     forward-addr: 1.0.0.1
EOF

# Download root hints for Unbound
mkdir -p /var/lib/unbound
curl -sSL https://www.internic.net/domain/named.root -o /var/lib/unbound/root.hints
chown unbound:unbound /var/lib/unbound/root.hints

# Enable and restart Unbound
systemctl enable unbound
systemctl restart unbound

# Test Unbound
echo "Testing Unbound..."
if dig @127.0.0.1 -p 5335 google.com +short > /dev/null 2>&1; then
    echo "✓ Unbound is working correctly"
else
    echo "⚠️  Unbound test failed - check logs with: journalctl -u unbound"
fi

# Configure Pi-hole to use Unbound
echo ""
echo "🔗 Configuring Pi-hole to use Unbound..."

# Update Pi-hole DNS settings
if [ -f /etc/pihole/setupVars.conf ]; then
    # Backup original
    cp /etc/pihole/setupVars.conf /etc/pihole/setupVars.conf.backup

    # Update DNS settings
    sed -i 's/^PIHOLE_DNS_.*$/PIHOLE_DNS_1=127.0.0.1#5335/' /etc/pihole/setupVars.conf

    # Remove any secondary DNS
    sed -i '/^PIHOLE_DNS_2/d' /etc/pihole/setupVars.conf

    # Enable DNSSEC
    sed -i 's/^DNSSEC=.*$/DNSSEC=true/' /etc/pihole/setupVars.conf || echo "DNSSEC=true" >> /etc/pihole/setupVars.conf

    # Restart Pi-hole DNS
    pihole restartdns
fi

echo "✓ Pi-hole configured to use Unbound"

# Install Python dependencies for network monitor
echo ""
echo "🔍 Installing network monitoring tools..."
pip3 install --break-system-packages scapy netifaces 2>/dev/null || pip3 install scapy netifaces

# Copy network monitor script
if [ -f "$(dirname $0)/netmonitor/monitor.py" ]; then
    cp "$(dirname $0)/netmonitor/monitor.py" "$INSTALL_DIR/scripts/"
    chmod +x "$INSTALL_DIR/scripts/monitor.py"
else
    echo "⚠️  Network monitor script not found, skipping..."
fi

# Create systemd service for network monitor
cat > /etc/systemd/system/homeguard-monitor.service <<EOF
[Unit]
Description=HomeGuard Network Monitor
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR/scripts
ExecStart=/usr/bin/python3 $INSTALL_DIR/scripts/monitor.py
Restart=always
RestartSec=10
StandardOutput=append:$INSTALL_DIR/logs/monitor.log
StandardError=append:$INSTALL_DIR/logs/monitor-error.log

[Install]
WantedBy=multi-user.target
EOF

# Enable network monitor (if script exists)
if [ -f "$INSTALL_DIR/scripts/monitor.py" ]; then
    systemctl enable homeguard-monitor
    systemctl start homeguard-monitor
    echo "✓ Network monitor service installed"
fi

# Configure Nginx for dashboard
echo ""
echo "🌐 Configuring web dashboard..."

# Stop and disable lighttpd (Pi-hole's web server) on port 80
# We'll proxy to it instead
systemctl stop lighttpd
sed -i 's/server.port.*=.*80/server.port = 8081/' /etc/lighttpd/lighttpd.conf
systemctl start lighttpd

# Create Nginx config
cat > /etc/nginx/sites-available/homeguard <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name homeguard homeguard.local _;

    root /var/www/homeguard;
    index index.html;

    # Main dashboard
    location / {
        try_files $uri $uri/ =404;
    }

    # Pi-hole admin interface (proxy to lighttpd on 8081)
    location /admin {
        proxy_pass http://127.0.0.1:8081/admin;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # API endpoints for dashboard (future)
    location /api/ {
        # Placeholder for future API
        return 501;
    }

    # Network monitor data
    location /data/devices.json {
        alias $DATA_DIR/netmonitor/devices.json;
        add_header Content-Type application/json;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/homeguard /etc/nginx/sites-enabled/homeguard
rm -f /etc/nginx/sites-enabled/default

# Copy web files
if [ -d "$(dirname $0)/../setup-wizard" ]; then
    cp -r "$(dirname $0)/../setup-wizard"/* $WEB_DIR/
    chown -R www-data:www-data $WEB_DIR
fi

# Restart Nginx
systemctl enable nginx
systemctl restart nginx

echo "✓ Web dashboard configured"

# Get network info
echo ""
echo "🌐 Network Configuration"
CURRENT_IP=$(hostname -I | awk '{print $1}')
GATEWAY=$(ip route | grep default | awk '{print $3}')

echo "Current IP: $CURRENT_IP"
echo "Gateway: $GATEWAY"

# Configure static IP (optional)
echo ""
read -p "Configure static IP for HomeGuard? (recommended) (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter static IP [$CURRENT_IP]: " STATIC_IP
    STATIC_IP=${STATIC_IP:-$CURRENT_IP}

    read -p "Enter gateway [$GATEWAY]: " STATIC_GATEWAY
    STATIC_GATEWAY=${STATIC_GATEWAY:-$GATEWAY}

    echo ""
    echo "Static IP Configuration:"
    echo "  IP: $STATIC_IP"
    echo "  Gateway: $STATIC_GATEWAY"
    echo ""
    echo "⚠️  Please configure static IP in your system network settings"
    echo "   On Raspberry Pi OS:"
    echo "   sudo nmtui"
    echo "   or edit /etc/dhcpcd.conf"
fi

# Create management script
cat > $INSTALL_DIR/homeguard <<'EOF'
#!/bin/bash
# HomeGuard Management Script

case "$1" in
    status)
        echo "HomeGuard Service Status:"
        echo ""
        systemctl status pihole-FTL --no-pager | head -3
        systemctl status unbound --no-pager | head -3
        systemctl status nginx --no-pager | head -3
        systemctl status homeguard-monitor --no-pager | head -3
        ;;
    restart)
        echo "Restarting HomeGuard services..."
        systemctl restart pihole-FTL
        systemctl restart unbound
        systemctl restart nginx
        systemctl restart homeguard-monitor
        echo "✓ Services restarted"
        ;;
    stop)
        echo "Stopping HomeGuard services..."
        systemctl stop pihole-FTL
        systemctl stop unbound
        systemctl stop nginx
        systemctl stop homeguard-monitor
        echo "✓ Services stopped"
        ;;
    start)
        echo "Starting HomeGuard services..."
        systemctl start unbound
        systemctl start pihole-FTL
        systemctl start nginx
        systemctl start homeguard-monitor
        echo "✓ Services started"
        ;;
    logs)
        if [ -z "$2" ]; then
            echo "Available logs: pihole, unbound, nginx, monitor"
            echo "Usage: homeguard logs <service>"
        else
            case "$2" in
                pihole) journalctl -u pihole-FTL -f ;;
                unbound) journalctl -u unbound -f ;;
                nginx) tail -f /var/log/nginx/error.log ;;
                monitor) tail -f /opt/homeguard/logs/monitor.log ;;
                *) echo "Unknown service: $2" ;;
            esac
        fi
        ;;
    update)
        echo "Updating HomeGuard..."
        pihole -up
        apt-get update && apt-get upgrade -y unbound nginx
        echo "✓ Update complete"
        ;;
    *)
        echo "HomeGuard Management"
        echo ""
        echo "Usage: homeguard {status|start|stop|restart|logs|update}"
        echo ""
        echo "Commands:"
        echo "  status   - Show service status"
        echo "  start    - Start all services"
        echo "  stop     - Stop all services"
        echo "  restart  - Restart all services"
        echo "  logs     - View logs (specify: pihole, unbound, nginx, monitor)"
        echo "  update   - Update all components"
        ;;
esac
EOF

chmod +x $INSTALL_DIR/homeguard
ln -sf $INSTALL_DIR/homeguard /usr/local/bin/homeguard

echo "✓ Management script installed"

# Final checks
echo ""
echo "🔍 Running final checks..."

# Test DNS resolution
if dig @127.0.0.1 google.com +short > /dev/null 2>&1; then
    echo "✓ DNS resolution working"
else
    echo "⚠️  DNS resolution test failed"
fi

# Test web interface
if curl -s http://127.0.0.1 > /dev/null; then
    echo "✓ Web interface accessible"
else
    echo "⚠️  Web interface not responding"
fi

echo ""
echo "=================================="
echo "   ✅ HomeGuard Pro Installed!"
echo "=================================="
echo ""
echo "📍 Access HomeGuard:"
echo "   Dashboard: http://$CURRENT_IP"
echo "   Pi-hole Admin: http://$CURRENT_IP/admin"
echo ""
echo "🔑 Pi-hole Admin Password:"
pihole -a -p
echo ""
echo "📝 Next Steps:"
echo "   1. Visit http://$CURRENT_IP to complete setup"
echo "   2. Configure your router DNS to: $CURRENT_IP"
echo "   3. Test by visiting any website"
echo ""
echo "🛠️  Management:"
echo "   homeguard status   - Check service status"
echo "   homeguard restart  - Restart all services"
echo "   homeguard logs     - View logs"
echo ""
echo "📊 Memory Usage:"
free -h
echo ""
