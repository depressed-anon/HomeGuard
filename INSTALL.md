# HomeGuard Pro - Installation Guide

Choose your installation method based on your use case.

## 🎯 Which Installation Method?

### ⭐ Complete Installation with Transparent Gateway (RECOMMENDED)

**Best for:**
- New installations from scratch
- Plug-and-play deployment
- Maximum protection with zero network configuration

**What you get:**
- ✅ Full security stack (Pi-hole, Unbound, Dashboard, Monitor)
- ✅ Transparent Gateway Mode (ARP spoofing + PVLAN)
- ✅ No router configuration needed
- ✅ Works with any existing network

```bash
# Flash Raspberry Pi OS, boot, then run:
curl -sSL https://raw.githubusercontent.com/YOUR-USERNAME/homeguard-pro/main/scripts/install-complete-transparent.sh | sudo bash
```

**Installation time:** 15-20 minutes (fully automated)

[📖 Full Complete Installation Guide →](#complete-installation-with-transparent-gateway)

---

### Native Installation (Modular)

**Best for:**
- Custom deployments
- Existing infrastructure integration
- Traditional DNS-only mode
- Maximum control over components

**Benefits:**
- 70% less RAM than Docker
- 3x faster boot time
- Standard Linux tools
- Professional systemd services

```bash
curl -sSL https://raw.githubusercontent.com/YOUR-USERNAME/homeguard-pro/main/scripts/install-native.sh | sudo bash
```

[📖 Full Native Installation Guide →](#native-installation-modular)

---

### Transparent Gateway Add-On

**Best for:**
- Already have Pi-hole/Unbound installed
- Want to add transparent gateway mode to existing setup
- Upgrading from traditional deployment

```bash
sudo /opt/homeguard/scripts/setup-transparent-gateway.sh
```

[📖 Transparent Gateway Setup Guide →](#transparent-gateway-add-on)

---

### Docker Installation

**Best for:**
- Laptop/Desktop (shared systems)
- Development and testing
- Multi-platform deployment
- Easy backup/restore

**Benefits:**
- Isolated containers
- Works on any OS with Docker
- Easy updates
- Clean uninstall

```bash
git clone https://github.com/YOUR-USERNAME/homeguard-pro.git
cd homeguard-pro
sudo docker-compose up -d
```

[📖 Full Docker Installation Guide →](#docker-installation)

---

## Complete Installation with Transparent Gateway

### What This Does

This master installation script sets up everything you need from scratch:

1. **Base System** - Updates OS and installs all dependencies
2. **Pi-hole** - DNS-based ad-blocking with web interface
3. **Unbound** - Private recursive DNS resolver (no third-party DNS)
4. **Dashboard** - Clean web interface for management
5. **Network Monitor** - Automatic device discovery
6. **Transparent Gateway** - ARP spoofing + PVLAN client isolation

**Result:** A fully functional network security appliance that transparently protects your entire network.

### Prerequisites

- Fresh Raspberry Pi OS installation (Bullseye or newer)
- Network connection (WiFi or Ethernet)
- Internet access
- 15-20 minutes

### Installation

```bash
# Option 1: Direct download and run (recommended)
curl -sSL https://raw.githubusercontent.com/YOUR-USERNAME/homeguard-pro/main/scripts/install-complete-transparent.sh | sudo bash

# Option 2: Clone repo first
git clone https://github.com/YOUR-USERNAME/homeguard-pro.git
cd homeguard-pro/scripts
sudo ./install-complete-transparent.sh
```

### What Happens During Installation

The script will:

1. ✅ Update system packages
2. ✅ Install dependencies (ebtables, arping, iptables, etc.)
3. ✅ Install and configure Pi-hole (automated)
4. ✅ Install and configure Unbound
5. ✅ Set up web dashboard
6. ✅ Install network monitoring service
7. ✅ Detect your network interface
8. ✅ Discover gateway automatically
9. ✅ Enable ARP spoofing (claim to be gateway)
10. ✅ Configure PVLAN (ebtables rules)
11. ✅ Set up DNS interception
12. ✅ Create management commands

**No user input required** - fully automated!

### After Installation

You'll see a summary with:

```
╔══════════════════════════════════════════════════════════════╗
║            ✓ HomeGuard Pro Installation Complete!           ║
╚══════════════════════════════════════════════════════════════╝

Installation Summary:
  HomeGuard IP: 192.168.1.100

Installed Components:
  ✓ Pi-hole          - DNS ad-blocking
  ✓ Unbound          - Recursive DNS resolver
  ✓ Dashboard        - Web interface (port 8080)
  ✓ Network Monitor  - Device discovery
  ✓ Transparent Mode - ARP spoofing + PVLAN

Access Points:
  Dashboard:  http://192.168.1.100:8080
  Pi-hole:    http://192.168.1.100/admin

Pi-hole Web Password: [random password shown here]

Management Commands:
  homeguard status              - Check all services
  homeguard-transparent status  - Check transparent mode
  homeguard restart             - Restart all services
```

### Verify It's Working

```bash
# Check all services
homeguard status

# Check transparent gateway
homeguard-transparent status

# Should show:
# ✓ ARP Spoofing: Active
# ✓ PVLAN Enforcement: Active
```

### Access Dashboard

Open your browser:
- **Main Dashboard:** `http://[your-pi-ip]:8080`
- **Pi-hole Admin:** `http://[your-pi-ip]/admin`

### What's Happening on Your Network

Once installed:

1. **All devices** on your network now route through HomeGuard (ARP spoofed)
2. **DNS queries** are filtered through Pi-hole (ads/trackers blocked)
3. **Clients are isolated** from each other (PVLAN prevents client-to-client attacks)
4. **Traffic is monitored** for threats
5. **No device configuration** needed - works transparently

### Management Commands

```bash
# Main commands
homeguard status              # Overall status
homeguard restart             # Restart all services
homeguard stop                # Stop all services
homeguard start               # Start all services

# Transparent gateway
homeguard-transparent status  # Detailed gateway status
homeguard-transparent logs    # View ARP spoofing logs
homeguard-transparent clients # List intercepted clients
homeguard-transparent stop    # Disable transparent mode
homeguard-transparent start   # Re-enable transparent mode

# Pi-hole
pihole status                 # Pi-hole status
pihole -g                     # Update blocklists
pihole restartdns             # Restart DNS service
```

### Troubleshooting

**Services not starting:**
```bash
# Check logs
journalctl -xe

# Check specific service
systemctl status pihole-FTL
systemctl status unbound
systemctl status homeguard-arpspoof
```

**DNS not working:**
```bash
# Test DNS resolution
dig @127.0.0.1 google.com

# Check Pi-hole
pihole status

# Check Unbound
dig @127.0.0.1 -p 5335 google.com
```

**Transparent mode not working:**
```bash
# Check ARP spoofing
homeguard-transparent status

# Check if clients are being intercepted
homeguard-transparent clients

# View logs
homeguard-transparent logs
```

---

## Native Installation (Modular)

### Prerequisites

- Raspberry Pi OS (Bullseye or newer)
- Internet connection via Ethernet
- SSH access or physical access
- 16GB+ SD card

### Step 1: Download Installer

```bash
# Option A: Direct download and run
curl -sSL https://raw.githubusercontent.com/YOUR-USERNAME/homeguard-pro/main/scripts/install-native.sh | sudo bash

# Option B: Clone repo first
git clone https://github.com/YOUR-USERNAME/homeguard-pro.git
cd homeguard-pro/scripts
sudo ./install-native.sh
```

### Step 2: Follow Installation Wizard

The installer will:
1. ✅ Install system dependencies
2. ✅ Install and configure Pi-hole
3. ✅ Configure Unbound DNS resolver
4. ✅ Set up Nginx web server
5. ✅ Install network monitoring service
6. ✅ Configure all services to auto-start

**Interactive prompts:**
- Pi-hole setup wizard (~5 minutes)
- Static IP configuration (optional but recommended)
- Admin password creation

**Installation time:** 10-15 minutes

### Step 3: Access Dashboard

Once installed, access at:
- **Main Dashboard:** `http://[YOUR-PI-IP]`
- **Pi-hole Admin:** `http://[YOUR-PI-IP]/admin`

Example: `http://192.168.1.100`

### Step 4: Configure Router

Set your router's DNS to your Pi's IP address.

**Router settings location:**
- Most routers: LAN/DHCP Settings
- Look for: "Primary DNS Server" or "DNS Server 1"
- Set to: Your Pi's IP (e.g., 192.168.1.100)

### Management Commands

```bash
homeguard status          # Check all services
homeguard restart         # Restart all services
homeguard stop            # Stop all services
homeguard start           # Start all services
homeguard logs pihole     # View Pi-hole logs
homeguard logs unbound    # View DNS resolver logs
homeguard update          # Update all components
```

### What Gets Installed

| Component | Purpose | Service Name |
|-----------|---------|--------------|
| Pi-hole | DNS ad-blocker | `pihole-FTL` |
| Unbound | Recursive DNS | `unbound` |
| Nginx | Web dashboard | `nginx` |
| Monitor | Device discovery | `homeguard-monitor` |

All services run as systemd services and auto-start on boot.

---

## Docker Installation

### Prerequisites

- Docker Engine 20.10+
- Docker Compose 1.29+
- 2GB+ RAM recommended
- Internet connection

### Step 1: Install Docker (if needed)

**On Raspberry Pi OS / Debian / Ubuntu:**
```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
```

Log out and back in for group changes to take effect.

### Step 2: Clone Repository

```bash
git clone https://github.com/YOUR-USERNAME/homeguard-pro.git
cd homeguard-pro
```

### Step 3: Configure (optional)

Edit `docker-compose.yml` to customize:
- Pi-hole admin password
- Timezone
- Port mappings

```yaml
environment:
  PIHOLE_PASSWORD: 'your_secure_password_here'
  TZ: 'America/New_York'
```

### Step 4: Start Services

```bash
# Start all containers
sudo docker-compose up -d

# Check status
sudo docker-compose ps

# View logs
sudo docker-compose logs -f
```

### Step 5: Access Dashboard

- **Setup Wizard:** `http://localhost:8080`
- **Dashboard:** `http://localhost:8080/dashboard.html`
- **Pi-hole Admin:** `http://localhost/admin`

If accessing from another device, replace `localhost` with your machine's IP.

### Step 6: Configure Network

**For network-wide protection**, edit `docker-compose.yml`:

Change port bindings from:
```yaml
ports:
  - "127.0.0.1:53:53/tcp"
```

To:
```yaml
ports:
  - "0.0.0.0:53:53/tcp"
```

Then restart:
```bash
sudo docker-compose down
sudo docker-compose up -d
```

### Management Commands

```bash
# Container management
docker-compose ps              # Status
docker-compose up -d           # Start
docker-compose down            # Stop
docker-compose restart         # Restart
docker-compose logs [service]  # View logs

# Updates
docker-compose pull            # Pull new images
docker-compose up -d           # Apply updates
```

### What Gets Installed

| Container | Purpose | Port(s) |
|-----------|---------|---------|
| `pihole` | DNS ad-blocker | 53, 80 |
| `unbound` | Recursive DNS | 5335 |
| `dashboard` | Web interface | 8080 |
| `netmonitor` | Device discovery | N/A |

---

## Post-Installation

### Step 1: Complete Setup Wizard

Visit the dashboard and follow the setup wizard:
1. Network configuration
2. Security settings
3. Admin password
4. Router setup instructions

### Step 2: Test DNS Blocking

```bash
# Test DNS resolution
dig @[YOUR-PI-IP] google.com

# Test ad blocking
dig @[YOUR-PI-IP] ads.google.com

# Should return 0.0.0.0 (blocked)
```

Or visit: http://pi.hole/admin and check query log

### Step 3: Configure Devices

**Option A: Router-wide (Recommended)**
- All devices protected automatically
- Configure once in router settings

**Option B: Per-device**
- Manual DNS configuration on each device
- More control, more work

### Step 4: Customize Blocking

In Pi-hole admin:
1. Go to Group Management → Adlists
2. Add additional blocklists
3. Update Gravity (Tools → Update Gravity)

**Popular blocklists:**
- OISD Big: `https://big.oisd.nl`
- Steven Black: `https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts`
- Hagezi Pro: `https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/hosts/pro.txt`

---

## Troubleshooting

### DNS Not Resolving

```bash
# Native
systemctl status pihole-FTL
systemctl status unbound
dig @127.0.0.1 google.com

# Docker
docker-compose ps
docker logs pihole
docker logs unbound
```

### Dashboard Not Loading

```bash
# Native
systemctl status nginx
sudo ss -tulpn | grep :80

# Docker
docker logs homeguard-dashboard
docker-compose ps
```

### High Memory Usage

```bash
# Check memory
free -h

# Reduce Pi-hole cache (native)
pihole -a -c 1000

# Restart services
# Native: homeguard restart
# Docker: docker-compose restart
```

### Port Conflicts

**Error:** "Port 80 already in use"

```bash
# Find what's using port 80
sudo ss -tulpn | grep :80

# Common culprits: Apache, Nginx, Lighttpd
# Stop conflicting service or change ports
```

---

## Uninstallation

### Native

```bash
# Stop services
homeguard stop

# Uninstall Pi-hole
pihole uninstall

# Remove packages
sudo apt-get remove --purge unbound nginx

# Remove data
sudo rm -rf /opt/homeguard
```

### Docker

```bash
# Stop and remove containers
docker-compose down

# Remove data volumes (optional)
docker-compose down -v

# Remove images (optional)
docker rmi $(docker images -q 'homeguard*')
```

---

## Next Steps

- 📖 Read [QUICKSTART.md](QUICKSTART.md) for quick reference
- 🔧 See [docs/installation-comparison.md](docs/installation-comparison.md) for detailed comparison
- 🛡️ Check [docs/wifi-demo-integration.md](docs/wifi-demo-integration.md) for sales funnel setup
- 💬 Join community discussions on GitHub

---

## Getting Help

- **Documentation:** `/opt/homeguard/docs/` (native) or `./docs/` (Docker)
- **Logs:** `homeguard logs [service]` (native) or `docker-compose logs` (Docker)
- **Pi-hole Forums:** https://discourse.pi-hole.net
- **GitHub Issues:** Report bugs and request features

---

**Ready to get started? Choose your installation method above!** 🚀
