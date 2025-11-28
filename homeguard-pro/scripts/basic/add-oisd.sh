#!/bin/bash
# Add OISD Big blocklist to Pi-hole safely

echo "Adding OISD Big blocklist to Pi-hole..."
echo ""

# Add to adlists file
podman exec pihole bash -c 'echo "https://big.oisd.nl/" >> /etc/pihole/adlists.list'

echo "✅ Blocklist URL added"
echo ""
echo "Updating gravity (this may take 30-60 seconds)..."
echo ""

# Update gravity to download and apply
podman exec pihole pihole -g

echo ""
echo "✅ Done! OISD Big blocklist is now active."
echo ""
echo "Check your Pi-hole dashboard to see the updated count:"
echo "http://127.0.0.1:8080/admin"
