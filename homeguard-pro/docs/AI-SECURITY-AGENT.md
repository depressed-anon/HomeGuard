# AI Security Agent - Enterprise Edition Concept

## Overview

Local AI-powered security analyst for Pi 5 8GB models that monitors Suricata IDS/IPS and Wazuh SIEM, detects attack patterns, and responds to intrusions automatically.

## Hardware Requirements

**Pi 5 8GB Only** - Enterprise Tier ($299)

**Resource Allocation:**
- Security Stack (Wazuh, Suricata, ClamAV): ~2.5-3GB
- Llama 3.2 3B (4-bit quantized): ~2-3GB
- OS + Overhead: ~500MB
- Free RAM Buffer: ~1.5-2GB

## AI Model

**Llama 3.2 3B** (4-bit quantization via Ollama)
- Inference time: ~10-15 seconds per analysis
- Good at pattern recognition and simple reasoning
- Runs locally, no API costs, fully offline

## Core Functionality

### What It Does

1. **Monitors Security Events**
   - Watches Suricata eve.json logs
   - Queries Wazuh API for SIEM events
   - Correlates alerts across both systems

2. **AI Analysis**
   - Distinguishes real attacks from false positives
   - Identifies coordinated attack patterns
   - Assesses threat level: Low/Medium/High/Critical
   - Recommends actions: Monitor/Block IP/Block Subnet/Isolate Device

3. **Automated Response**
   - Auto-blocks malicious IPs/subnets
   - Whitelists known false positives
   - Creates iptables rules
   - Logs incidents
   - Sends alerts to admin

### Example Scenarios

**Scenario 1: Single Port Scan**
```
Input: Suricata detects port scan from 1.2.3.4
AI: "Single scan, no follow-up. Low threat."
Action: Log only, no block
```

**Scenario 2: Coordinated Attack**
```
Input:
  - Port scan from 1.2.3.4
  - SSH bruteforce from 1.2.3.5
  - SQL injection from 1.2.3.6
AI: "Multiple IPs from same /24 coordinating. Active attack."
Action: Block 1.2.3.0/24, email alert, create incident report
```

**Scenario 3: False Positive**
```
Input: Suspicious user agent from internal IP 192.168.1.50
AI: "Internal device, likely phone app. Not a threat."
Action: Whitelist, suppress future alerts
```

## Architecture

```
/opt/homeguard/ai-agent/
├── ollama/                    # Llama 3.2 3B model
├── monitor.py                 # Watches Suricata + Wazuh logs
├── analyzer.py                # Feeds events to LLM
├── responder.py               # Takes automated actions
├── config.yaml                # Thresholds, response rules
└── ai-agent.service           # systemd service
```

### AI Prompt Template

```
You are a security analyst for a home network. Analyze these events:

[Suricata events from last 5 minutes]
[Wazuh alerts from last 5 minutes]

Determine:
1. Is this a real attack or false positive?
2. Threat level: Low/Medium/High/Critical
3. Recommended action: Monitor/Block IP/Block Subnet/Isolate Device

Respond in JSON format only.
```

### Execution

- Runs every 5 minutes (scheduled)
- OR triggered immediately on critical alerts
- Falls back to rule-based blocking if LLM unavailable
- Only analyzes when events exist (not constant polling)

## Progressive Web App (PWA) Interface

### Why PWA Instead of Native App

**Decision:** Use Progressive Web App instead of native iOS/Android apps

**Rationale:**
1. **Push notifications work** - Web Push API supported on iOS 16.4+ and Android
2. **Faster development** - One codebase vs separate iOS/Android apps (2-3 weeks vs 10-14 weeks)
3. **No app store gatekeepers** - No approval delays, no $99/year fees, instant updates
4. **Works everywhere** - Desktop, mobile, tablet from same codebase
5. **Proven model** - Pi-hole, pfSense, Home Assistant use web interfaces successfully
6. **Update freedom** - Push updates instantly, no waiting for app store approval

### PWA Features

**Installation:**
```
1. User visits https://homeguard.local
2. Browser prompts: "Add HomeGuard to Home Screen?"
3. User taps "Add"
4. Icon appears on home screen
5. Launches fullscreen like native app
```

**Push Notifications:**
```javascript
// Web Push API
self.addEventListener('push', function(event) {
  const data = event.data.json();
  self.registration.showNotification(data.title, {
    body: data.body,
    icon: '/icon-512.png',
    badge: '/badge-96.png',
    vibrate: [200, 100, 200],
    data: { url: data.url },
    actions: [
      { action: 'view', title: 'View Details' },
      { action: 'dismiss', title: 'Dismiss' }
    ]
  });
});
```

**Example Notification:**
```
⚠️ High Threat Detected
AI blocked coordinated attack from 5 IPs
[View Details] [Dismiss]
```

**Manifest Configuration:**
```json
{
  "name": "HomeGuard Security",
  "short_name": "HomeGuard",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#667eea",
  "theme_color": "#667eea",
  "orientation": "portrait",
  "icons": [
    {
      "src": "/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

### Mobile Dashboard Features

**Real-time Threat Feed:**
- Live updates via WebSocket or Server-Sent Events
- AI analysis results
- Blocked IPs/devices
- Attack timelines
- Severity indicators (Low/Medium/High/Critical)

**Admin Controls:**
- Approve/deny AI recommendations
- Manual block/unblock IPs
- Whitelist false positives
- Configure AI sensitivity
- Emergency lockdown mode
- View incident reports

**Network Visibility:**
- Connected devices list
- Traffic graphs
- Top talkers
- Blocked connections
- DNS query logs

**System Status:**
- AI agent health
- Suricata status
- Wazuh status
- CPU/RAM/disk usage
- Uptime

### Backend API

```
REST API: /api/

Endpoints:
  GET  /threats              - Recent AI threat alerts
  POST /threats/:id/block    - Block IP/subnet from threat
  POST /threats/:id/whitelist - Whitelist false positive
  GET  /devices              - List network devices
  POST /devices/:id/isolate  - Isolate compromised device
  GET  /status               - System health status
  GET  /ai/analysis          - Recent AI analysis results
  POST /ai/settings          - Configure AI sensitivity
  GET  /incidents            - AI incident reports
  POST /actions/lockdown     - Emergency network lockdown
```

**WebSocket for Real-time:**
```
ws://homeguard.local/ws/threats

Messages:
  { "type": "new_threat", "data": {...} }
  { "type": "ai_analysis", "data": {...} }
  { "type": "device_blocked", "data": {...} }
```

**Push Notification Backend:**
```python
from pywebpush import webpush, WebPushException

def send_threat_notification(threat_level, message, details_url):
    """Send push notification to all subscribed admins"""
    if threat_level in ['High', 'Critical']:
        for subscription in get_admin_subscriptions():
            try:
                webpush(
                    subscription_info=subscription,
                    data=json.dumps({
                        "title": f"⚠️ {threat_level} Threat Detected",
                        "body": message,
                        "url": details_url,
                        "icon": "/icon-512.png"
                    }),
                    vapid_private_key=VAPID_PRIVATE_KEY,
                    vapid_claims={
                        "sub": "mailto:admin@homeguard.local"
                    }
                )
            except WebPushException as e:
                log.error(f"Push failed: {e}")
```

### User Experience Flow

**Initial Setup:**
1. Complete wizard on desktop/laptop
2. Visit https://homeguard.local on phone
3. Browser prompts "Add to Home Screen"
4. Tap "Add"
5. Grant notification permission
6. Done - icon on home screen

**Daily Use:**
1. AI detects coordinated attack
2. Push notification appears on phone
3. User taps notification
4. PWA opens to threat details
5. Shows AI analysis and recommendation
6. User taps "Block All" or "Whitelist"
7. Action applied instantly

**Mobile Experience:**
- Looks identical to native app
- Works offline (cached with Service Worker)
- Fast load times
- Native-like animations
- Swipe gestures
- Bottom navigation
- Pull-to-refresh

## Product Differentiation

| Feature | Premium (4GB) | Enterprise (8GB) |
|---------|---------------|------------------|
| Wazuh SIEM | ✅ | ✅ |
| Suricata IDS/IPS | ✅ | ✅ |
| ClamAV | ✅ | ✅ |
| AI Security Agent | ❌ | ✅ |
| Mobile PWA | ⚠️ Basic | ✅ Full Featured |
| Push Alerts | ❌ | ✅ |
| Auto-response | ❌ | ✅ |

## Implementation Phases

**Phase 1: AI Agent Backend**
- Install Ollama + Llama 3.2 3B
- Build Python monitoring daemon
- Integrate with Suricata/Wazuh
- Automated response system

**Phase 2: REST API & WebSocket**
- REST API for threat management
- WebSocket for real-time updates
- Admin authentication/authorization
- API documentation

**Phase 3: PWA Enhancement**
- Mobile-responsive dashboard improvements
- Service Worker for offline support
- Web Push notification integration
- manifest.json for installable PWA
- Threat visualization UI

**Phase 4: Polish**
- AI model fine-tuning on home network patterns
- Response optimization
- User feedback loop
- Performance optimization
- Comprehensive testing

## Notes

- This is **Enterprise tier only** (requires 8GB RAM)
- Fully local, no cloud dependencies
- No API costs
- Privacy-focused (data never leaves device)
- Falls back gracefully if AI unavailable
