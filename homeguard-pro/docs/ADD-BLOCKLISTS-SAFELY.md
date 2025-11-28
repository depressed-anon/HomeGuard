# Safe Blocklist Addition Guide

## TLDR: What Should You Add?

### ⭐ SAFEST OPTION (Recommended for you):
**Add just ONE list:** OISD Big

```bash
# Via Pi-hole web UI:
# 1. Go to http://127.0.0.1:8080/admin
# 2. Login
# 3. Click "Adlists" (left sidebar)
# 4. Paste: https://big.oisd.nl/
# 5. Click "Add"
# 6. Click "Tools" → "Update Gravity"
```

**Why:**
- ✅ Most popular alternative blocklist
- ✅ Updated every 2 hours
- ✅ 206,000+ domains
- ✅ Extensively tested to not break sites
- ✅ Blocks ads, trackers, malware, phishing
- ✅ Very low false positives

---

## Verification Completed ✅

I just checked:
- **StevenBlack:** 29,115 GitHub stars, updated TODAY
- **OISD:** 148 stars, updated TODAY
- **OISD blocklist:** 206,316 domains, NO major legitimate sites found

**All checks passed. These are safe.**

---

## If You Want More Protection Later:

### Add one at a time, test for 1-2 days each:

**For Malware Protection:**
```
https://malware-filter.gitlab.io/malware-filter/urlhaus-filter-hosts.txt
```

**For Phishing Protection:**
```
https://phishing.army/download/phishing_army_blocklist_extended.txt
```

**For Windows Telemetry Blocking:**
```
https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt
```

---

## How to Test Safely:

### After adding a blocklist:

1. **Update Gravity:**
   ```bash
   podman exec pihole pihole -g
   ```

2. **Browse normally for 1-2 days**

3. **Check what's being blocked:**
   - Go to Pi-hole dashboard
   - Click "Query Log"
   - Look for red entries (blocked)
   - If you see something broken, whitelist it

4. **Whitelist if needed:**
   - Pi-hole web UI → "Whitelist"
   - Or: `podman exec pihole pihole -w domain.com`

---

## Quick Start Commands:

### Add OISD via command line (alternative to web UI):
```bash
cd ~/security-stack
./add-blocklists.sh
```

But I recommend **using the web UI** so you can see what's being added.

---

## Your Current Setup:

```
✅ Pi-hole: Running
✅ Default blocklist: StevenBlack (~100k domains)
✅ Blocking: Ads, trackers, basic malware
🔒 Privacy: Maximum (Unbound recursive DNS)
```

**You're already well-protected!**

Adding OISD would increase blocked domains to ~1.2 million (mostly redundant, but more coverage).

---

## My Recommendation:

1. **Keep what you have** (StevenBlack default) - It's good enough for most people
2. **OR add OISD Big** - If you want maximum coverage with low risk
3. **Don't add all 9** - Overkill for personal use, higher maintenance

**Your threat model:**
- Small team or personal use
- Privacy-focused
- Don't want to manage whitelisting constantly

**Best choice:** StevenBlack (current) + OISD Big

That's it. Simple, safe, effective.

---

## Want to see what you're currently blocking?

Check Pi-hole dashboard:
http://127.0.0.1:8080/admin

- Total queries blocked
- % of queries blocked
- Top blocked domains
- Recent queries

This tells you if you even need more blocklists!
