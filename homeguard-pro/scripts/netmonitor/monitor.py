#!/usr/bin/env python3
"""
HomeGuard Network Monitor
Discovers and monitors devices on the network
"""

import socket
import subprocess
import json
import time
from datetime import datetime
from pathlib import Path
import re

DATA_DIR = Path('/data')
DEVICES_FILE = DATA_DIR / 'devices.json'
LOG_FILE = DATA_DIR / 'network_activity.log'

def get_network_info():
    """Get current network configuration"""
    try:
        # Get default gateway
        result = subprocess.run(['ip', 'route', 'show', 'default'],
                              capture_output=True, text=True)
        gateway_match = re.search(r'default via ([\d.]+)', result.stdout)
        gateway = gateway_match.group(1) if gateway_match else None

        # Get local IP
        hostname = socket.gethostname()
        local_ip = socket.gethostbyname(hostname)

        return {
            'gateway': gateway,
            'local_ip': local_ip,
            'network': '.'.join(local_ip.split('.')[:-1]) + '.0/24'
        }
    except Exception as e:
        log(f"Error getting network info: {e}")
        return None

def scan_network(network):
    """Scan network for active devices using arp-scan"""
    devices = []

    try:
        # Use arp-scan for fast network discovery
        result = subprocess.run(['arp-scan', '--localnet', '--quiet'],
                              capture_output=True, text=True, timeout=30)

        for line in result.stdout.split('\n'):
            # Parse arp-scan output: IP    MAC    Manufacturer
            parts = line.split('\t')
            if len(parts) >= 2:
                ip = parts[0].strip()
                mac = parts[1].strip()
                vendor = parts[2].strip() if len(parts) > 2 else 'Unknown'

                # Try to get hostname
                hostname = get_hostname(ip)

                devices.append({
                    'ip': ip,
                    'mac': mac,
                    'hostname': hostname,
                    'vendor': vendor,
                    'last_seen': datetime.now().isoformat(),
                    'status': 'online'
                })

    except subprocess.TimeoutExpired:
        log("Network scan timed out")
    except FileNotFoundError:
        # Fallback to nmap if arp-scan not available
        try:
            result = subprocess.run(['nmap', '-sn', network],
                                  capture_output=True, text=True, timeout=60)
            # Parse nmap output
            ip_pattern = r'Nmap scan report for ([\d.]+)'
            for match in re.finditer(ip_pattern, result.stdout):
                ip = match.group(1)
                hostname = get_hostname(ip)
                devices.append({
                    'ip': ip,
                    'hostname': hostname,
                    'last_seen': datetime.now().isoformat(),
                    'status': 'online'
                })
        except Exception as e:
            log(f"Fallback scan failed: {e}")
    except Exception as e:
        log(f"Network scan error: {e}")

    return devices

def get_hostname(ip):
    """Attempt to resolve hostname from IP"""
    try:
        hostname, _, _ = socket.gethostbyaddr(ip)
        return hostname
    except:
        return ip

def load_devices():
    """Load known devices from file"""
    if DEVICES_FILE.exists():
        try:
            with open(DEVICES_FILE, 'r') as f:
                return json.load(f)
        except:
            return {}
    return {}

def save_devices(devices):
    """Save devices to file"""
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with open(DEVICES_FILE, 'w') as f:
        json.dump(devices, f, indent=2)

def update_device_database(new_devices):
    """Update device database with newly discovered devices"""
    known_devices = load_devices()

    for device in new_devices:
        mac = device.get('mac', device['ip'])

        if mac in known_devices:
            # Update existing device
            known_devices[mac]['last_seen'] = device['last_seen']
            known_devices[mac]['status'] = 'online'
            known_devices[mac]['ip'] = device['ip']  # Update IP if changed
        else:
            # New device detected
            known_devices[mac] = device
            log(f"New device detected: {device['hostname']} ({device['ip']})")

    # Mark devices not seen as offline
    current_ips = {d['ip'] for d in new_devices}
    for mac, device in known_devices.items():
        if device['ip'] not in current_ips and device['status'] == 'online':
            device['status'] = 'offline'
            log(f"Device went offline: {device['hostname']} ({device['ip']})")

    save_devices(known_devices)
    return known_devices

def get_network_stats():
    """Get basic network statistics"""
    stats = {
        'timestamp': datetime.now().isoformat(),
        'total_devices': 0,
        'online_devices': 0,
        'offline_devices': 0
    }

    devices = load_devices()
    stats['total_devices'] = len(devices)
    stats['online_devices'] = sum(1 for d in devices.values() if d['status'] == 'online')
    stats['offline_devices'] = stats['total_devices'] - stats['online_devices']

    return stats

def log(message):
    """Write to log file"""
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    with open(LOG_FILE, 'a') as f:
        f.write(f"[{timestamp}] {message}\n")
    print(f"[{timestamp}] {message}")

def main():
    """Main monitoring loop"""
    log("HomeGuard Network Monitor started")

    scan_interval = 60  # Scan every 60 seconds

    while True:
        try:
            # Get network info
            network_info = get_network_info()
            if not network_info:
                log("Could not determine network configuration")
                time.sleep(scan_interval)
                continue

            log(f"Scanning network: {network_info['network']}")

            # Scan for devices
            discovered_devices = scan_network(network_info['network'])
            log(f"Found {len(discovered_devices)} active devices")

            # Update database
            all_devices = update_device_database(discovered_devices)

            # Get stats
            stats = get_network_stats()
            log(f"Network stats: {stats['online_devices']} online, {stats['offline_devices']} offline")

            # Wait before next scan
            time.sleep(scan_interval)

        except KeyboardInterrupt:
            log("Monitor stopped by user")
            break
        except Exception as e:
            log(f"Error in main loop: {e}")
            time.sleep(scan_interval)

if __name__ == '__main__':
    main()
