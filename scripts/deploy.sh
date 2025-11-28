#!/bin/bash
# HomeGuard Pro Deployment Script
# Deploys HomeGuard on Raspberry Pi or any Linux system

set -e

echo "=================================="
echo "   HomeGuard Pro Deployment"
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

# Install dependencies
echo ""
echo "📦 Installing dependencies..."

if [ "$OS" = "raspbian" ] || [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
    apt-get update -qq
    apt-get install -y \
        docker.io \
        docker-compose \
        python3 \
        python3-pip \
        arp-scan \
        nmap \
        git \
        curl
else
    echo "⚠️  Unsupported OS. Please install Docker manually."
    exit 1
fi

# Enable and start Docker
systemctl enable docker
systemctl start docker

echo "✓ Dependencies installed"

# Create deployment directory
INSTALL_DIR="/opt/homeguard"
echo ""
echo "📁 Creating installation directory: $INSTALL_DIR"
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# Copy files if running from source
if [ -d "$(dirname $0)/.." ]; then
    echo "📋 Copying files from source..."
    cp -r $(dirname $0)/../* $INSTALL_DIR/
fi

# Create data directories
mkdir -p data/{pihole,netmonitor}
mkdir -p configs/{unbound,nginx}

# Create minimal unbound config if it doesn't exist
if [ ! -f configs/unbound/unbound.conf ]; then
    echo "📝 Creating default Unbound configuration..."
    cat > configs/unbound/unbound.conf <<'EOF'
server:
    verbosity: 1
    interface: 0.0.0.0
    port: 5335
    do-ip4: yes
    do-ip6: no
    do-udp: yes
    do-tcp: yes
    access-control: 0.0.0.0/0 allow
    hide-identity: yes
    hide-version: yes
    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: yes
    cache-min-ttl: 3600
    cache-max-ttl: 86400
    prefetch: yes
    num-threads: 2
    msg-cache-slabs: 4
    rrset-cache-slabs: 4
    infra-cache-slabs: 4
    key-cache-slabs: 4
    rrset-cache-size: 100m
    msg-cache-size: 50m
    so-rcvbuf: 1m
EOF
fi

# Create nginx config if it doesn't exist
if [ ! -f configs/nginx/nginx.conf ]; then
    echo "📝 Creating default Nginx configuration..."
    cat > configs/nginx/nginx.conf <<'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 80;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html;

        location / {
            try_files $uri $uri/ =404;
        }

        location /api/ {
            # Future API endpoints
            return 503;
        }
    }
}
EOF
fi

# Set permissions
chmod +x scripts/deploy.sh 2>/dev/null || true

# Get network configuration
echo ""
echo "🌐 Network Configuration"
echo "-----------------------"

# Detect current IP
CURRENT_IP=$(hostname -I | awk '{print $1}')
echo "Current IP: $CURRENT_IP"

# Prompt for static IP configuration
read -p "Would you like to set a static IP for HomeGuard? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter desired IP address [$CURRENT_IP]: " STATIC_IP
    STATIC_IP=${STATIC_IP:-$CURRENT_IP}

    read -p "Enter gateway IP [192.168.1.1]: " GATEWAY_IP
    GATEWAY_IP=${GATEWAY_IP:-192.168.1.1}

    echo "Setting static IP: $STATIC_IP"
    # Note: This would need to be adapted for different network managers
    echo "⚠️  Please manually configure static IP in your system settings"
    echo "   IP Address: $STATIC_IP"
    echo "   Gateway: $GATEWAY_IP"
fi

# Create .env file
echo ""
echo "🔧 Creating configuration..."
cat > .env <<EOF
SERVER_IP=${STATIC_IP:-$CURRENT_IP}
PIHOLE_PASSWORD=changeme123
TZ=America/New_York
EOF

echo "✓ Configuration created"

# Start services
echo ""
echo "🚀 Starting HomeGuard services..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to start (30 seconds)..."
sleep 30

# Check if services are running
echo ""
echo "🔍 Checking service status..."
docker-compose ps

echo ""
echo "=================================="
echo "   ✅ HomeGuard Pro Deployed!"
echo "=================================="
echo ""
echo "📍 Access HomeGuard:"
echo "   Setup Wizard: http://${STATIC_IP:-$CURRENT_IP}:8080"
echo "   Dashboard: http://homeguard.local:8080"
echo "   Pi-hole Admin: http://${STATIC_IP:-$CURRENT_IP}/admin"
echo ""
echo "🔑 Default Pi-hole password: changeme123"
echo "   Change it at: http://${STATIC_IP:-$CURRENT_IP}/admin/settings.php"
echo ""
echo "📝 Next Steps:"
echo "   1. Complete the setup wizard at http://${STATIC_IP:-$CURRENT_IP}:8080"
echo "   2. Configure your router to use ${STATIC_IP:-$CURRENT_IP} as DNS server"
echo "   3. Change the Pi-hole admin password"
echo ""
echo "📖 Documentation: $INSTALL_DIR/docs/README.md"
echo ""
