# Blocklist Reputation & Safety Report

## How to Verify Each List is Trustworthy:

### 1. **StevenBlack Unified Hosts** ✅ HIGHLY TRUSTED
- **Source:** https://github.com/StevenBlack/hosts
- **GitHub Stars:** 36,000+ ⭐⭐⭐⭐⭐
- **Maintainer:** Steven Black (public figure, verifiable)
- **Since:** 2012 (13 years maintained)
- **Users:** Millions worldwide
- **Transparency:** Fully open source, every domain visible
- **Community:** Active issues/PRs, responsive maintainer
- **Already enabled in your Pi-hole by default** ✅

**Verdict:** Industry standard, extremely safe

---

### 2. **URLhaus Malware Filter** ✅ TRUSTED
- **Source:** https://gitlab.com/malware-filter/malware-filter
- **Upstream:** abuse.ch (Swiss cybersecurity nonprofit)
- **Purpose:** Confirmed malware distribution domains
- **Updated:** Multiple times daily
- **Validation:** Domains verified by security researchers
- **False Positives:** Very low (only confirmed malware)
- **Reputation:** Used by security professionals

**Verdict:** Safe, malware-specific, low risk of breakage

---

### 3. **OSINT Digital Side Threat Intel** ⚠️ MODERATE TRUST
- **Source:** https://osint.digitalside.it
- **Maintainer:** Italian OSINT collective
- **Purpose:** Threat intelligence from multiple sources
- **Updated:** Daily
- **Risk:** Aggregates from multiple sources (some may have false positives)

**Verdict:** Good for security, but test first

---

### 4. **Phishing Army** ✅ TRUSTED
- **Source:** https://phishing.army
- **Purpose:** Phishing and scam domains
- **Methodology:** Crowdsourced + automated verification
- **Updated:** Hourly
- **False Positives:** Low (focused on confirmed phishing)

**Verdict:** Safe, phishing-specific

---

### 5. **HaGeZi Pro** ✅ TRUSTED
- **Source:** https://github.com/hagezi/dns-blocklists
- **GitHub Stars:** 5,000+
- **Maintainer:** HaGeZi (known in Pi-hole community)
- **Purpose:** Comprehensive ad/tracker/threat blocking
- **Testing:** Extensively tested by community
- **Tiers:** Multiple lists (Pro is aggressive but safe)

**Verdict:** Well-maintained, community-vetted

---

### 6. **OISD Big** ✅ HIGHLY TRUSTED
- **Source:** https://oisd.nl / https://github.com/sjhgvr/oisd
- **Maintainer:** Stephan van Ruth (Netherlands)
- **Users:** 100,000+
- **Philosophy:** "Block. Don't break."
- **Testing:** Extensive automated testing
- **False Positives:** Very low (tested across thousands of sites)
- **Updates:** Every 2 hours
- **Community:** Active Discord, responsive to reports

**Verdict:** Extremely safe, most popular alternative to StevenBlack

---

### 7. **CoinBlocker** ✅ TRUSTED
- **Source:** https://gitlab.com/ZeroDot1/CoinBlockerLists
- **Purpose:** Block cryptocurrency miners
- **Scope:** Narrow focus (only crypto miners)
- **Risk:** Very low (specific use case)

**Verdict:** Safe, niche protection

---

### 8. **Amnesty Tech NSO Group** ✅ HIGHLY TRUSTED
- **Source:** https://github.com/AmnestyTech/investigations
- **Organization:** Amnesty International (human rights NGO)
- **Purpose:** Block NSO Group Pegasus spyware infrastructure
- **Domains:** ~100 (very small list)
- **Risk:** Zero (highly targeted, verified)

**Verdict:** Extremely safe, ethical source

---

### 9. **Windows Spy Blocker** ✅ TRUSTED
- **Source:** https://github.com/crazy-max/WindowsSpyBlocker
- **GitHub Stars:** 5,000+
- **Purpose:** Block Windows telemetry
- **Scope:** Microsoft telemetry domains only
- **Risk:** May break Windows Update (whitelisting may be needed)

**Verdict:** Safe but may require whitelisting for updates

---

## Recommended Safe Combination:

### **Conservative (Start Here):**
1. StevenBlack (already enabled) ✅
2. OISD Big ← Add this one

**Total domains:** ~1.2 million
**Breakage risk:** Very low

### **Balanced Security:**
1. StevenBlack ✅
2. OISD Big
3. URLhaus Malware
4. Phishing Army

**Total domains:** ~1.5 million
**Breakage risk:** Low

### **Maximum Protection:**
All 9 lists

**Total domains:** ~3-4 million
**Breakage risk:** Medium (may need whitelisting)

---

## How to Verify Before Adding:

### Method 1: Check GitHub/GitLab Repository
- Look for stars/forks (popularity)
- Read issues (community feedback)
- Check last update (actively maintained?)
- Review commits (transparent changes?)

### Method 2: Download and Inspect
```bash
curl -s https://big.oisd.nl/ | head -100
```

Look for:
- ✅ Blocking suspicious domains (ads, malware, trackers)
- ❌ Blocking legitimate sites (google.com, amazon.com)
- ✅ Using 0.0.0.0 or 127.0.0.1 redirects
- ❌ Using weird IP redirects (potential hijacking)

### Method 3: Test One at a Time
1. Add blocklist
2. Update gravity: `podman exec pihole pihole -g`
3. Browse normally for 1-2 days
4. Check Pi-hole query log for false positives
5. Whitelist if needed or remove list

### Method 4: Check Pi-hole Community
- https://discourse.pi-hole.net
- Search for blocklist name
- Read user experiences
- See if reported issues

---

## Red Flags (DO NOT ADD):

❌ No public source code/repository
❌ Anonymous maintainer with no history
❌ Blocks major legitimate sites
❌ Uses non-localhost IP redirects
❌ No clear purpose/documentation
❌ Not updated in 6+ months
❌ Negative community feedback

---

## Bottom Line:

**All 9 lists I recommended are legitimate and trusted by the security community.**

**Start with:** OISD Big (safest, most comprehensive)
**Add later:** Others as needed based on threats you care about

**Your call:** How aggressive do you want to be?
