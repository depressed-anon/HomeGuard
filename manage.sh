#!/bin/bash
# Security Stack Management Script

cd ~/security-stack

case "$1" in
    start)
        echo "Starting security stack..."
        podman-compose up -d
        ;;
    stop)
        echo "Stopping security stack..."
        podman-compose down
        ;;
    restart)
        echo "Restarting security stack..."
        podman-compose restart
        ;;
    status)
        echo "Security Stack Status:"
        podman-compose ps
        ;;
    logs)
        if [ -z "$2" ]; then
            podman-compose logs --tail=50
        else
            podman-compose logs --tail=50 "$2"
        fi
        ;;
    install-service)
        echo "Installing systemd service..."
        mkdir -p ~/.config/systemd/user/
        cp security-stack.service ~/.config/systemd/user/
        systemctl --user daemon-reload
        systemctl --user enable security-stack.service
        systemctl --user start security-stack.service
        echo "Service installed and started!"
        echo "The stack will now auto-start on boot."
        ;;
    uninstall-service)
        echo "Uninstalling systemd service..."
        systemctl --user stop security-stack.service
        systemctl --user disable security-stack.service
        rm ~/.config/systemd/user/security-stack.service
        systemctl --user daemon-reload
        echo "Service uninstalled."
        ;;
    configure-dns)
        ./configure-dns.sh
        ;;
    *)
        echo "Security Stack Manager"
        echo ""
        echo "Usage: $0 {start|stop|restart|status|logs|install-service|uninstall-service|configure-dns}"
        echo ""
        echo "Commands:"
        echo "  start              - Start all containers"
        echo "  stop               - Stop all containers"
        echo "  restart            - Restart all containers"
        echo "  status             - Show container status"
        echo "  logs [service]     - Show logs (optionally for specific service)"
        echo "  install-service    - Install systemd service for auto-start on boot"
        echo "  uninstall-service  - Remove systemd service"
        echo "  configure-dns      - Configure system to use local DNS"
        echo ""
        echo "Services: pihole, unbound, squid, dante"
        exit 1
        ;;
esac
