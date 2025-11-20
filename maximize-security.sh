#!/bin/bash
# Master script to maximize security on your system

clear
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         SECURITY STACK - MAXIMUM PROTECTION SETUP         ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "This will configure multiple security layers:"
echo ""
echo "  Layer 1: Host Firewall (UFW)"
echo "  Layer 2: Enhanced DNS Blocklists"
echo "  Layer 3: VPN for Traffic Encryption"
echo "  Layer 4: Brute Force Protection (Fail2Ban)"
echo "  Layer 5: Automated Security Updates"
echo ""
echo "Current Status:"
echo "  ✅ Pi-hole + Unbound (DNS Privacy)"
echo "  ✅ Squid + Dante (Proxies)"
echo "  ✅ Auto-start on Boot"
echo "  ✅ OISD Blocklist (~272k domains)"
echo ""
read -p "Continue with security maximization? (y/n): " continue

if [ "$continue" != "y" ]; then
    echo "Cancelled. Run this script again when ready."
    exit 0
fi

# Track progress
STEPS_COMPLETED=0
TOTAL_STEPS=5

echo ""
echo "═══════════════════════════════════════════════════════════"
echo " LAYER 1: HOST FIREWALL"
echo "═══════════════════════════════════════════════════════════"
echo ""
read -p "Configure firewall (UFW)? (y/n): " do_firewall
if [ "$do_firewall" == "y" ]; then
    echo "Run this command in your terminal:"
    echo "  sudo ~/security-stack/configure-firewall.sh"
    echo ""
    read -p "Press Enter when done..."
    ((STEPS_COMPLETED++))
else
    echo "Skipped."
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo " LAYER 2: ENHANCED BLOCKLISTS"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Add security-focused blocklists:"
echo "  • Malware domains"
echo "  • Phishing sites"
echo "  • Crypto miners"
echo "  • Spyware (NSO Pegasus)"
echo "  • Windows telemetry"
echo ""
read -p "Add security blocklists? (y/n): " do_blocklists
if [ "$do_blocklists" == "y" ]; then
    ~/security-stack/add-security-blocklists.sh
    ((STEPS_COMPLETED++))
else
    echo "Skipped."
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo " LAYER 3: VPN (TRAFFIC ENCRYPTION)"
echo "═══════════════════════════════════════════════════════════"
echo ""
read -p "Set up VPN? (y/n): " do_vpn
if [ "$do_vpn" == "y" ]; then
    ~/security-stack/setup-wireguard.sh
    ((STEPS_COMPLETED++))
else
    echo "Skipped."
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo " LAYER 4: BRUTE FORCE PROTECTION"
echo "═══════════════════════════════════════════════════════════"
echo ""
read -p "Install Fail2Ban? (y/n): " do_fail2ban
if [ "$do_fail2ban" == "y" ]; then
    ~/security-stack/setup-fail2ban.sh
    ((STEPS_COMPLETED++))
else
    echo "Skipped."
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo " LAYER 5: AUTOMATED SECURITY UPDATES"
echo "═══════════════════════════════════════════════════════════"
echo ""
read -p "Enable automatic security updates? (y/n): " do_updates
if [ "$do_updates" == "y" ]; then
    echo "Installing unattended-upgrades..."
    sudo apt-get install -y unattended-upgrades
    sudo dpkg-reconfigure --priority=low unattended-upgrades
    ((STEPS_COMPLETED++))
    echo "✅ Automatic security updates enabled"
else
    echo "Skipped."
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo " SETUP COMPLETE"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Completed $STEPS_COMPLETED out of $TOTAL_STEPS security layers"
echo ""
echo "Your Security Posture:"
echo ""

if [ $STEPS_COMPLETED -eq 0 ]; then
    echo "  Privacy: ⭐⭐⭐⭐⭐ (Excellent)"
    echo "  Security: ⭐⭐☆☆☆ (Basic)"
elif [ $STEPS_COMPLETED -le 2 ]; then
    echo "  Privacy: ⭐⭐⭐⭐⭐ (Excellent)"
    echo "  Security: ⭐⭐⭐☆☆ (Good)"
elif [ $STEPS_COMPLETED -le 4 ]; then
    echo "  Privacy: ⭐⭐⭐⭐⭐ (Excellent)"
    echo "  Security: ⭐⭐⭐⭐☆ (Very Good)"
else
    echo "  Privacy: ⭐⭐⭐⭐⭐ (Excellent)"
    echo "  Security: ⭐⭐⭐⭐⭐ (Maximum)"
fi

echo ""
echo "Next Steps:"
echo "  • Check Pi-hole dashboard: http://127.0.0.1:8080/admin"
echo "  • Test DNS: dig google.com"
echo "  • Monitor logs: ~/security-stack/manage.sh logs"
echo ""
echo "To manage your stack:"
echo "  ~/security-stack/manage.sh {start|stop|restart|status|logs}"
echo ""
echo "Documentation: ~/security-stack/README.md"
echo ""
