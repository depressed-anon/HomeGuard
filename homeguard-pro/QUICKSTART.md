# HomeGuard Pro - Quick Start Guide

**Get your network security appliance running in 10 minutes**

## Prerequisites

- Raspberry Pi (any model with Ethernet)
- Fresh Raspberry Pi OS installation
- Internet connection via Ethernet
- SSH access enabled

## Installation (One Command)

```bash
curl -sSL https://raw.githubusercontent.com/YOUR-USERNAME/homeguard-pro/main/scripts/install-native.sh | sudo bash
```

Or download and run:

```bash
git clone https://github.com/YOUR-USERNAME/homeguard-pro.git
cd homeguard-pro/scripts
sudo ./install-native.sh
```

## What Gets Installed

The script automatically installs and configures:

1. **Pi-hole** - DNS-based ad blocker
2. **Unbound** - Private recursive DNS resolver
3. **Nginx** - Web server for dashboard
4. **Network Monitor** - Device discovery service

All services are configured as systemd services (no Docker required).

## During Installation

You'll be asked:

1. **Pi-hole setup** - Follow the wizard (5 minutes)
   - Select interface: `eth0`
   - Upstream DNS: Custom `127.0.0.1#5335`
   - Web interface: Yes
   - Web server: Yes

2. **Static IP** (recommended) - Enter your desired IP
   - Example: `192.168.1.100`

3. **Admin password** - Create a secure password

Installation takes 5-10 minutes depending on your internet speed.

## After Installation

### Step 1: Access Dashboard

Open your browser and go to:
- `http://[YOUR-PI-IP]` - Main dashboard
- `http://[YOUR-PI-IP]/admin` - Pi-hole admin

Example: `http://192.168.1.100`

### Step 2: Configure Your Router

**Method 1: Router-Wide Protection (Recommended)**

1. Log into your router admin panel
2. Find DHCP/DNS settings
3. Set Primary DNS to your Pi's IP
4. Save and reboot router

Now ALL devices are protected automatically!

**Method 2: Per-Device Configuration**

Set DNS manually on each device:
- Primary DNS: `[Your Pi IP]`
- Secondary DNS: `1.1.1.1` (backup)

### Step 3: Test It Works

1. Visit http://pi.hole/admin
2. You should see query statistics
3. Try visiting an ad-heavy website
4. Check Pi-hole dashboard - ads should be blocked!

## Management Commands

```bash
# Check status
homeguard status

# Restart all services
homeguard restart

# View logs
homeguard logs pihole
homeguard logs unbound
homeguard logs nginx
homeguard logs monitor

# Update everything
homeguard update

# Stop all services
homeguard stop

# Start all services
homeguard start
```

## Troubleshooting

### DNS Not Working

```bash
# Test Unbound
dig @127.0.0.1 -p 5335 google.com

# Test Pi-hole
dig @127.0.0.1 google.com

# Check services
homeguard status
```

### Dashboard Not Loading

```bash
# Check Nginx
systemctl status nginx

# Check if port 80 is in use
sudo ss -tulpn | grep :80

# Restart web server
sudo systemctl restart nginx
```

### High Memory Usage

```bash
# Check memory
free -h

# If using Pi Zero, reduce Pi-hole cache
pihole -a -c 1000

# Restart services to clear memory
homeguard restart
```

## Resource Usage

**Typical RAM usage on Raspberry Pi:**

| Model | Total RAM | HomeGuard Usage | Available for OS |
|-------|-----------|-----------------|------------------|
| Pi Zero 2 W | 512 MB | ~120 MB | ~380 MB |
| Pi 3 B+ | 1 GB | ~130 MB | ~850 MB |
| Pi 4 (2GB) | 2 GB | ~140 MB | ~1.8 GB |
| Pi 5 (4GB) | 4 GB | ~150 MB | ~3.8 GB |

All models run smoothly with native installation!

## Next Steps

1. **Customize blocking** - Add blocklists in Pi-hole admin
2. **Set up VPN** - WireGuard for secure remote access (coming soon)
3. **Monitor devices** - View all connected devices in dashboard
4. **Weekly reports** - Enable email reports in Pi-hole settings

## Getting Help

- Documentation: `/opt/homeguard/docs/`
- Check logs: `homeguard logs [service]`
- Pi-hole community: https://discourse.pi-hole.net
- HomeGuard issues: GitHub Issues

---

**That's it! Your network is now protected.** 🛡️
