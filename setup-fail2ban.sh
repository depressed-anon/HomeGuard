#!/bin/bash
# Install and configure fail2ban for brute force protection

echo "=== Fail2Ban Setup ==="
echo ""
echo "Fail2Ban automatically blocks IPs that attempt:"
echo "  ✓ SSH brute force attacks"
echo "  ✓ Repeated login failures"
echo "  ✓ Port scanning"
echo ""

read -p "Install fail2ban? (y/n): " install

if [ "$install" != "y" ]; then
    echo "Skipping fail2ban installation."
    exit 0
fi

echo ""
echo "Installing fail2ban..."
sudo apt-get update
sudo apt-get install -y fail2ban

echo ""
echo "Creating configuration..."

# Create local jail configuration
sudo tee /etc/fail2ban/jail.local > /dev/null <<'EOF'
[DEFAULT]
# Ban for 1 hour
bantime = 3600
# Check for 5 failures
maxretry = 5
# Within 10 minutes
findtime = 600

# Email alerts (optional)
# destemail = your@email.com
# sendername = Fail2Ban
# action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log

[recidive]
# Ban repeat offenders for 1 week
enabled = true
bantime = 604800
findtime = 86400
maxretry = 3
EOF

echo "✅ Configuration created"
echo ""
echo "Starting fail2ban..."
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

echo ""
echo "✅ Fail2Ban is now active!"
echo ""
echo "Check status:"
echo "  sudo fail2ban-client status"
echo ""
echo "Check banned IPs:"
echo "  sudo fail2ban-client status sshd"
