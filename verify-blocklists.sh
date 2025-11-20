#!/bin/bash
# Verify blocklists are safe before adding them

echo "=== BLOCKLIST SAFETY VERIFICATION ==="
echo ""

# Function to check a blocklist
check_blocklist() {
    local url="$1"
    local name="$2"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 Checking: $name"
    echo "🔗 URL: $url"
    echo ""

    # Download and analyze
    echo "⬇️  Downloading sample (first 100 lines)..."
    curl -s "$url" | head -100 > /tmp/blocklist_sample.txt

    if [ $? -ne 0 ]; then
        echo "❌ ERROR: Could not download blocklist!"
        return 1
    fi

    # Count total domains
    total_lines=$(curl -s "$url" | wc -l)
    echo "📊 Total lines: $total_lines"

    # Count actual blocking rules (ignore comments)
    blocking_rules=$(curl -s "$url" | grep -v "^#" | grep -v "^$" | wc -l)
    echo "🚫 Blocking rules: $blocking_rules"

    # Show sample of what gets blocked
    echo ""
    echo "📝 Sample of blocked domains (first 10):"
    grep -v "^#" /tmp/blocklist_sample.txt | grep -v "^$" | head -10

    # Check for suspicious patterns
    echo ""
    echo "🔍 Safety checks:"

    # Check if blocking legitimate sites
    suspicious=$(grep -v "^#" /tmp/blocklist_sample.txt | grep -E "(google\.com|amazon\.com|microsoft\.com|apple\.com|github\.com)$" | head -5)
    if [ -n "$suspicious" ]; then
        echo "⚠️  WARNING: Found potentially legitimate domains:"
        echo "$suspicious"
    else
        echo "✅ No major legitimate sites detected in sample"
    fi

    # Check for localhost/private IPs (should block to 0.0.0.0 or 127.0.0.1)
    bad_ips=$(grep -v "^#" /tmp/blocklist_sample.txt | grep -v -E "^(0\.0\.0\.0|127\.0\.0\.1)" | grep -E "^[0-9]+\." | head -5)
    if [ -n "$bad_ips" ]; then
        echo "⚠️  WARNING: Found unusual IP redirects:"
        echo "$bad_ips"
    else
        echo "✅ IP redirects look safe (0.0.0.0 or 127.0.0.1)"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Check each blocklist
check_blocklist "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" "StevenBlack Unified Hosts"

check_blocklist "https://malware-filter.gitlab.io/malware-filter/urlhaus-filter-hosts.txt" "URLhaus Malware Filter"

check_blocklist "https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt" "OSINT Digital Side Threat Intel"

check_blocklist "https://phishing.army/download/phishing_army_blocklist_extended.txt" "Phishing Army"

check_blocklist "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/pro.txt" "HaGeZi Pro"

check_blocklist "https://big.oisd.nl/" "OISD Big List"

check_blocklist "https://zerodot1.gitlab.io/CoinBlockerLists/hosts_browser" "CoinBlocker Browser"

check_blocklist "https://raw.githubusercontent.com/AmnestyTech/investigations/master/2021-07-18_nso/domains.txt" "Amnesty Tech NSO Group"

check_blocklist "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt" "Windows Spy Blocker"

echo ""
echo "=== VERIFICATION COMPLETE ==="
echo ""
echo "Review the output above. Look for:"
echo "✅ Legitimate blocking targets (ads, trackers, malware)"
echo "❌ Legitimate sites being blocked (would break functionality)"
echo "⚠️  Unusual IP redirects (security risk)"
echo ""
echo "If everything looks good, you can add the lists you trust."
