# Security Stack

A containerized privacy and security infrastructure running on your laptop.

## What's Running

- **Pi-hole** (port 53, 8080) - DNS with ad/tracker blocking + Web UI
- **Unbound** (port 5335) - Recursive DNS resolver for maximum privacy
- **Squid** (port 3128) - HTTP/HTTPS caching proxy
- **Dante** (port 1080) - SOCKS5 proxy

## Architecture

```
Your Apps → Pi-hole (blocks ads) → Unbound (recursive DNS) → Root DNS servers
Your Browser → Squid Proxy (HTTP) or Dante (SOCKS5) → Internet
```

## Quick Start

### Check Status
```bash
cd ~/security-stack
./manage.sh status
```

### Start/Stop/Restart
```bash
./manage.sh start
./manage.sh stop
./manage.sh restart
```

### View Logs
```bash
./manage.sh logs           # All services
./manage.sh logs pihole    # Specific service
```

### Configure System DNS (One-time setup)
```bash
./manage.sh configure-dns
```
This makes your system use Pi-hole for all DNS queries automatically.

### Enable Auto-Start on Boot
```bash
./manage.sh install-service
```

### Disable Auto-Start
```bash
./manage.sh uninstall-service
```

## Access Services

### Pi-hole Web Interface
- URL: http://127.0.0.1:8080/admin
- Password: (the one you set with `podman exec pihole pihole setpassword`)

### Using the Proxies

**Squid HTTP Proxy:**
```bash
export http_proxy=http://127.0.0.1:3128
export https_proxy=http://127.0.0.1:3128
```

**SOCKS5 Proxy:**
```bash
curl -x socks5://127.0.0.1:1080 http://example.com
```

Or configure your browser:
- Firefox: Settings → Network Settings → Manual proxy
  - SOCKS Host: 127.0.0.1, Port: 1080
  - SOCKS v5

## Manual Control

### Using podman-compose directly
```bash
cd ~/security-stack
podman-compose up -d        # Start
podman-compose down          # Stop
podman-compose restart squid # Restart one service
podman-compose logs -f       # Follow logs
```

### Change Pi-hole Password
```bash
podman exec pihole pihole setpassword 'YourNewPassword'
```

## File Structure

```
~/security-stack/
├── docker-compose.yml       # Main configuration
├── manage.sh                # Management script
├── configure-dns.sh         # DNS configuration script
├── README.md                # This file
├── unbound/
│   └── unbound.conf         # Unbound config
├── pihole/
│   ├── etc-pihole/          # Pi-hole settings (auto-created)
│   └── etc-dnsmasq.d/       # DNS config (auto-created)
├── squid/
│   ├── squid.conf           # Squid configuration
│   ├── cache/               # Squid cache data
│   └── logs/                # Squid logs
└── socks/                   # (Dante doesn't need volumes)
```

## Troubleshooting

### Containers won't start
```bash
cd ~/security-stack
podman-compose down
podman-compose up -d
```

### Check specific service logs
```bash
podman logs pihole
podman logs unbound
podman logs squid
podman logs dante
```

### DNS not working
```bash
# Test DNS directly
dig @127.0.0.1 google.com

# Check if Pi-hole is running
podman ps | grep pihole
```

### Reset everything
```bash
cd ~/security-stack
podman-compose down
rm -rf pihole/ squid/cache/ squid/logs/
podman-compose up -d
```

## Expanding to Router

When you're ready to share this with other devices via a router:

1. Change port bindings in docker-compose.yml from `127.0.0.1:53` to `0.0.0.0:53`
2. Configure router to use your laptop's IP for DNS
3. Configure firewall to allow connections from router network

## Notes

- All data is stored in `~/security-stack/` - easy to backup
- Containers auto-restart unless stopped manually
- Pi-hole password is stored in its database, not in docker-compose.yml
- Special characters in YAML passwords can cause issues - use simple passwords or change via CLI
