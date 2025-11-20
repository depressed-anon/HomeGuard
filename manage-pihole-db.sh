#!/bin/bash
# Manage Pi-hole database from host system

PIHOLE_CONTAINER="pihole"
LOCAL_DB="/tmp/pihole-gravity.db"

# Function to add a blocklist
add_blocklist() {
    local url="$1"
    local comment="$2"

    echo "Adding blocklist: $url"

    # Copy database from container
    podman cp ${PIHOLE_CONTAINER}:/etc/pihole/gravity.db ${LOCAL_DB}

    # Add blocklist
    sqlite3 ${LOCAL_DB} "INSERT OR IGNORE INTO adlist (address, enabled, comment) VALUES ('${url}', 1, '${comment}');"

    # Copy back to container
    podman cp ${LOCAL_DB} ${PIHOLE_CONTAINER}:/etc/pihole/gravity.db

    # Update gravity
    echo "Updating gravity..."
    podman exec ${PIHOLE_CONTAINER} pihole -g

    # Cleanup
    rm -f ${LOCAL_DB}

    echo "✅ Blocklist added!"
}

# Function to list blocklists
list_blocklists() {
    echo "Current blocklists:"
    podman cp ${PIHOLE_CONTAINER}:/etc/pihole/gravity.db ${LOCAL_DB}
    sqlite3 ${LOCAL_DB} "SELECT id, address, enabled, comment FROM adlist;" | column -t -s '|'
    rm -f ${LOCAL_DB}
}

# Main
case "$1" in
    add)
        if [ -z "$2" ]; then
            echo "Usage: $0 add <URL> [comment]"
            exit 1
        fi
        add_blocklist "$2" "$3"
        ;;
    list)
        list_blocklists
        ;;
    add-oisd)
        add_blocklist "https://big.oisd.nl/domainswild2" "OISD Big - Comprehensive Safe List"
        ;;
    *)
        echo "Pi-hole Database Manager"
        echo ""
        echo "Usage: $0 {add|list|add-oisd}"
        echo ""
        echo "Commands:"
        echo "  add <URL> [comment]  - Add a blocklist"
        echo "  list                 - List all blocklists"
        echo "  add-oisd             - Add OISD Big list (recommended)"
        echo ""
        echo "Examples:"
        echo "  $0 add-oisd"
        echo "  $0 add https://example.com/blocklist.txt 'My custom list'"
        echo "  $0 list"
        exit 1
        ;;
esac
