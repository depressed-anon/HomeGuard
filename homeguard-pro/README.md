# HomeGuard Pro - Network Security Appliance

**Transform any Raspberry Pi into a powerful network security appliance**

HomeGuard Pro protects your entire home or office network from ads, trackers, malware, and online threats - with zero configuration required.

## 🎯 What It Does

- **Network-Wide Ad Blocking** - Blocks ads on every device automatically
- **Privacy Protection** - Stops trackers and data collection
- **Malware Defense** - Blocks malicious domains before they load
- **Device Monitoring** - See and manage all connected devices
- **Simple Dashboard** - User-friendly web interface
- **VPN Ready** - Secure remote access capability

## 🚀 Quick Start

### Deployment Modes

HomeGuard Pro offers multiple deployment modes to fit your network setup:

#### 🔹 **Transparent Gateway Mode** (NEW - Recommended)

**Zero configuration** - Just plug into your existing network!

```bash
# Connect to your network (WiFi or Ethernet)
# Then run:
cd /opt/homeguard
sudo ./scripts/setup-transparent-gateway.sh
```

**What it does:**
- Transparently intercepts all network traffic (ARP spoofing)
- Enforces client isolation (software PVLAN)
- No router configuration needed
- No managed switches required
- Works with any existing network

[📖 Read Transparent Gateway Architecture](docs/transparent-gateway-architecture.md)

#### 🔹 **Traditional Deployment**

**Full control** - Replace your router or act as DNS server.

```bash
# Download and run the deployment script
curl -sSL https://raw.githubusercontent.com/depressed-anon/homeguard-pro/main/scripts/deploy.sh | sudo bash
```

**What it does:**
- HomeGuard acts as DNS server
- Requires router DNS configuration
- More traditional setup
- Maximum compatibility

#### 🔹 **Pre-Built Image** (Coming Soon)

Download the HomeGuard Pro image and flash it to your SD card using Raspberry Pi Imager.

## 📋 Requirements

### Hardware
- **Minimum:** Raspberry Pi Zero 2 W
- **Recommended:** Raspberry Pi 4 (2GB+ RAM)
- **Premium:** Raspberry Pi 5 or Rock Pi 4

### Software
- Raspberry Pi OS (Bullseye or newer)
- Docker & Docker Compose (auto-installed by script)
- 16GB+ SD card

### Network
- Ethernet connection to router
- Static IP recommended
- Router admin access for DNS configuration

## 🎨 Features

### Core Security Stack

| Component | Purpose | Port |
|-----------|---------|------|
| Pi-hole | DNS-based ad blocking | 53, 80 |
| Unbound | Private recursive DNS resolver | 5335 |
| Dashboard | Web management interface | 8080 |
| Net Monitor | Device discovery & monitoring | N/A |

### Setup Wizard

First-time setup takes just 3 minutes:

1. **Network Configuration** - Automatic DHCP or manual static IP
2. **Security Level** - Choose protection: Standard, Family Safe, or Maximum
3. **Admin Password** - Secure your dashboard
4. **Router Setup** - Step-by-step DNS configuration guide

### Enhanced Dashboard

Beautiful, responsive interface showing:
- Real-time blocking statistics
- Connected devices with icons
- Recent activity log
- Quick actions and settings
- Network health monitoring

### Network Monitoring

Automatic device discovery shows:
- Device name and type
- IP and MAC addresses
- Online/offline status
- Manufacturer information
- Connection history

## 📖 Post-Installation Setup

### Step 1: Complete Setup Wizard

1. Navigate to `http://homeguard.local:8080` or `http://[YOUR-IP]:8080`
2. Follow the setup wizard
3. Set a strong admin password
4. Choose your protection level

### Step 2: Configure Your Router

**Option A: Use HomeGuard as Network DNS (Recommended)**

1. Log into your router admin panel
2. Find DHCP/DNS settings
3. Set Primary DNS to your HomeGuard IP (e.g., 192.168.1.100)
4. Set Secondary DNS to 1.1.1.1 (backup)
5. Save and reboot router

**Option B: Manual Device Configuration**

Configure DNS on each device:
- Set DNS server to HomeGuard's IP address
- Works immediately without router changes

### Step 3: Test Protection

1. Visit http://pi.hole/admin to access Pi-hole
2. Check that queries are being logged
3. Try visiting a known ad site - it should be blocked
4. View blocked domains in real-time

## 🔧 Configuration

### Adjusting Protection Levels

Edit `docker-compose.yml` environment variables:

```yaml
pihole:
  environment:
    - WEBPASSWORD=your_secure_password
    - PIHOLE_DNS_=unbound#5335
    - DNSSEC=true
```

### Adding Custom Blocklists

1. Access Pi-hole admin: `http://homeguard.local/admin`
2. Go to Group Management → Adlists
3. Add your custom blocklist URLs
4. Update gravity: Tools → Update Gravity

### Customizing Dashboard

Edit `/setup-wizard/dashboard.html` to customize:
- Colors and branding
- Statistics displayed
- Quick action buttons
- Activity log format

## 🛠️ Management

### Start/Stop Services

```bash
cd /opt/homeguard
docker-compose stop    # Stop all services
docker-compose start   # Start all services
docker-compose restart # Restart all services
```

### View Logs

```bash
docker-compose logs pihole      # Pi-hole logs
docker-compose logs unbound     # DNS resolver logs
docker-compose logs netmonitor  # Network monitoring logs
```

### Update HomeGuard

```bash
cd /opt/homeguard
git pull
docker-compose pull
docker-compose up -d
```

### Backup Configuration

```bash
# Backup all data
tar -czf homeguard-backup-$(date +%Y%m%d).tar.gz /opt/homeguard/data

# Restore from backup
tar -xzf homeguard-backup-YYYYMMDD.tar.gz -C /
```

## 🔒 Security Best Practices

1. **Change default password** immediately after installation
2. **Use static IP** to prevent DNS configuration issues
3. **Enable HTTPS** for dashboard access (optional)
4. **Regular updates** - Run updates monthly
5. **Backup configs** before making changes
6. **Monitor logs** for suspicious activity

## 📊 Monitoring & Statistics

### Pi-hole Statistics

- Total queries blocked
- Percentage of blocked requests
- Top blocked domains
- Query types breakdown
- Client activity

### Device Monitoring

- Number of connected devices
- Device identification
- Bandwidth usage (coming soon)
- Per-device blocking statistics

## 🐛 Troubleshooting

### Services Won't Start

```bash
# Check Docker status
sudo systemctl status docker

# Restart Docker
sudo systemctl restart docker

# Check container logs
docker-compose logs
```

### DNS Not Working

```bash
# Test DNS resolution
dig @192.168.1.100 google.com

# Check Pi-hole is listening
sudo netstat -tulpn | grep :53

# Verify containers are running
docker-compose ps
```

### Dashboard Not Accessible

```bash
# Check Nginx container
docker logs homeguard-dashboard

# Verify port 8080 is open
sudo ss -tulpn | grep :8080

# Restart dashboard
docker-compose restart dashboard
```

### Network Monitor Not Detecting Devices

```bash
# Check network monitor logs
docker logs netmonitor

# Verify host network mode
docker inspect netmonitor | grep NetworkMode

# Manually install arp-scan
sudo apt-get install arp-scan
```

## 🎁 Commercial Features (Planned)

### HomeGuard Pro Premium ($5/month)

- ☁️ Cloud dashboard access
- 📧 Email/SMS threat alerts
- 📊 Advanced analytics & reports
- 👨‍👩‍👧‍👦 Family controls per device
- 🔐 VPN server (WireGuard)
- 💬 Priority support

### HomeGuard Enterprise ($50/month)

- 🏢 Multi-site management
- 📁 Active Directory integration
- 📋 Compliance reporting
- 📞 24/7 phone support
- 🎯 Custom blocklists
- 🔄 Managed updates

## 🤝 Contributing

HomeGuard Pro is open source! Contributions welcome:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📝 License

MIT License - See LICENSE file for details

## 🔗 Links

- **Documentation**: https://docs.homeguard.local (coming soon)
- **GitHub**: https://github.com/depressed-anon/homeguard-pro
- **Community Discord**: [Join here] (coming soon)
- **Support Email**: support@homeguard.local

## 💡 Educational Demo Integration

HomeGuard pairs perfectly with WiFi security education demonstrations:

1. **Run WiFi security demo** at events/conferences
2. **Show real-world risks** using provocative network names
3. **Offer HomeGuard** as the solution for home network protection
4. **Special discount code** for demo participants

See `/docs/wifi-demo-integration.md` for setup instructions.

---

**Made with ❤️ for network security education**

*Protect your network. Protect your privacy. Protect your family.*
