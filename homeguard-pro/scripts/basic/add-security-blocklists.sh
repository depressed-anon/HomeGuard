#!/bin/bash
# Add security-focused blocklists (malware, phishing, ransomware)

cd ~/security-stack

echo "Adding security-focused blocklists to Pi-hole..."
echo ""

# Malware
echo "1/5 Adding URLhaus Malware blocklist..."
./manage-pihole-db.sh add "https://malware-filter.gitlab.io/malware-filter/urlhaus-filter-hosts.txt" "URLhaus - Malware Distribution"

# Phishing
echo "2/5 Adding Phishing Army blocklist..."
./manage-pihole-db.sh add "https://phishing.army/download/phishing_army_blocklist_extended.txt" "Phishing Army - Phishing Protection"

# Cryptominers
echo "3/5 Adding CoinBlocker..."
./manage-pihole-db.sh add "https://zerodot1.gitlab.io/CoinBlockerLists/hosts_browser" "CoinBlocker - Cryptocurrency Miners"

# Spyware (NSO Group Pegasus)
echo "4/5 Adding Amnesty Tech NSO blocklist..."
./manage-pihole-db.sh add "https://raw.githubusercontent.com/AmnestyTech/investigations/master/2021-07-18_nso/domains.txt" "Amnesty Tech - NSO Pegasus Spyware"

# Windows Telemetry
echo "5/5 Adding Windows Spy Blocker..."
./manage-pihole-db.sh add "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt" "Windows Spy Blocker - Telemetry"

echo ""
echo "✅ All security blocklists added!"
echo ""
echo "Total protection now includes:"
echo "  ✓ Malware domains"
echo "  ✓ Phishing sites"
echo "  ✓ Crypto miners"
echo "  ✓ Spyware infrastructure"
echo "  ✓ OS telemetry"
echo ""
echo "Check Pi-hole dashboard: http://127.0.0.1:8080/admin"
