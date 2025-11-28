# HomeGuard Pro - Project Structure

This document explains the organization of the HomeGuard Pro codebase.

## Directory Overview

```
homeguard-pro/
├── docs/                          # All documentation
├── scripts/                       # All executable scripts
│   ├── basic/                    # Basic setup scripts
│   ├── advanced/                 # Advanced features
│   ├── vpn/                      # VPN integration
│   └── netmonitor/               # Network monitoring
├── setup-wizard/                 # Web-based setup wizard
├── deployment/                   # Deployment configurations
│   └── docker/                   # Docker-related files
├── legacy/                       # Old configuration files (reference)
└── [root files]                  # LICENSE, README, etc.
```

---

## Root Files

| File | Purpose |
|------|---------|
| **README.md** | Main project documentation and quick start |
| **INSTALL.md** | Detailed installation instructions |
| **QUICKSTART.md** | Quick setup guide |
| **LICENSE** | MIT License |
| **CLA.md** | Contributor License Agreement |
| **CONTRIBUTING.md** | How to contribute to the project |
| **docker-compose.yml** | Main Docker deployment configuration |
| **SUMMARY.md** | Project summary and overview |
| **VPN-INTEGRATION-SUMMARY.md** | VPN features documentation |

---

## `/docs/` - Documentation

All documentation files are stored here:

### Architecture & Design
- **transparent-gateway-architecture.md** - How transparent gateway mode works
- **docker-vs-native.md** - Deployment comparison
- **installation-comparison.md** - Installation methods comparison
- **COMPETITIVE-ANALYSIS.md** - Comparison with Firewalla, Ubiquiti, etc.

### Features
- **AI-SECURITY-AGENT.md** - AI-powered threat detection (Enterprise tier)
- **WIZARD-VPN-INTEGRATION.md** - VPN integration in setup wizard
- **wifi-demo-integration.md** - WiFi integration demo

### Security & Configuration
- **SECURITY-LAYERS.md** - Multi-layer security architecture
- **ADD-BLOCKLISTS-SAFELY.md** - How to add blocklists safely
- **blocklist-reputation-check.md** - Blocklist verification guide

---

## `/scripts/` - Executable Scripts

### `/scripts/basic/` - Core Setup Scripts

**DNS Configuration:**
- `configure-dns.sh` - Set up Pi-hole and Unbound DNS

**Firewall:**
- `configure-firewall.sh` - Basic firewall rules

**Security:**
- `setup-fail2ban.sh` - Fail2ban intrusion prevention

**Blocklists:**
- `add-oisd.sh` - Add OISD blocklist
- `add-security-blocklists.sh` - Add security-focused blocklists
- `verify-blocklists.sh` - Verify blocklist integrity

**Utilities:**
- `install-sqlite.sh` - Install SQLite for Pi-hole

### `/scripts/advanced/` - Advanced Features

- `setup-wireguard.sh` - WireGuard VPN server setup
- `install-nordvpn.sh` - NordVPN client integration
- `maximize-security.sh` - Comprehensive security hardening

### `/scripts/vpn/` - VPN Client Integration

- `configure-vpn.sh` - Master VPN configuration script
- `providers/` - Provider-specific scripts
  - `mullvad.sh` - Mullvad VPN configuration
  - `nordvpn.sh` - NordVPN configuration
  - `protonvpn.sh` - ProtonVPN configuration
  - etc.

### `/scripts/netmonitor/` - Network Monitoring

- `monitor.py` - Python-based network monitoring daemon

### Root-Level Scripts

- `install-complete-transparent.sh` - **Main installation script** (recommended)
- `install-native.sh` - Native (non-Docker) installation
- `setup-transparent-gateway.sh` - Set up transparent gateway mode
- `deploy.sh` - Deployment automation
- `manage.sh` - System management commands
- `manage-pihole-db.sh` - Pi-hole database management

---

## `/setup-wizard/` - Web-Based Setup

- `index.html` - Main setup wizard (6-step process)
  - Step 1: Welcome
  - Step 2: Network configuration
  - Step 3: Security settings
  - Step 4: VPN integration (optional)
  - Step 5: VPN provider configuration
  - Step 6: Complete

- `dashboard.html` - Admin dashboard (placeholder)
- `setup.html` - Alternative setup page

**Access:** http://homeguard.local/ (after installation)

---

## `/deployment/` - Deployment Configurations

### `/deployment/docker/`

- `docker-compose-legacy.yml` - Legacy Docker Compose setup (from original HomeGuard)

**Note:** Main `docker-compose.yml` is in project root.

---

## `/legacy/` - Legacy Files (Reference Only)

Files from the original HomeGuard project, kept for reference:

- `README-LEGACY.md` - Original project README
- `security-stack.service` - systemd service file (old)
- `add-suricata.yml` - Suricata configuration
- `enhanced-blocklists.txt` - Blocklist collection

**Note:** These are reference files. Current implementations are in `/scripts/`.

---

## Hardware Tiers

HomeGuard Pro supports different hardware configurations:

| Tier | Hardware | Price | Features |
|------|----------|-------|----------|
| **Basic** | Pi Zero 2W | $99 | DNS + VPN client |
| **Standard** | Pi 4 4GB | $149 | Basic + monitoring |
| **Premium** | Pi 5 4GB | $249 | Standard + Wazuh + Suricata |
| **Enterprise** | Pi 5 8GB | $299 | Premium + AI security agent |

---

## Installation Paths

### Quick Start (Recommended)
```bash
sudo bash scripts/install-complete-transparent.sh
```

### Custom Installation
1. Read `/docs/installation-comparison.md`
2. Choose Docker or native deployment
3. Follow `/INSTALL.md` instructions

### Web Wizard
1. Install base system
2. Visit http://homeguard.local/
3. Follow 6-step wizard

---

## Development Workflow

### Contributing
1. Read `CONTRIBUTING.md`
2. Agree to `CLA.md` by submitting a PR
3. Follow coding standards

### Testing
```bash
# Test installation (dry run)
sudo bash scripts/install-complete-transparent.sh --test

# Test VPN config
sudo bash scripts/vpn/configure-vpn.sh --dry-run
```

---

## Key Features by Directory

**Want DNS ad blocking?** → `/scripts/basic/`
**Want VPN integration?** → `/scripts/vpn/`
**Want AI security?** → `/docs/AI-SECURITY-AGENT.md` (Enterprise only)
**Want transparent gateway?** → `/scripts/setup-transparent-gateway.sh`
**Want easy setup?** → `/setup-wizard/`

---

## File Naming Conventions

- **Scripts:** `kebab-case.sh`
- **Docs:** `SCREAMING-KEBAB.md` for major docs, `kebab-case.md` for technical docs
- **Config:** `service-name.yml` or `service-name.conf`

---

## License

All code is MIT licensed. See `LICENSE` file.

Contributors agree to `CLA.md` terms when submitting pull requests.

---

## Questions?

- **General:** Open a GitHub issue
- **Security:** Email maintainer (don't open public issue)
- **Contributing:** Read `CONTRIBUTING.md`

---

**Last Updated:** 2025-11-28
