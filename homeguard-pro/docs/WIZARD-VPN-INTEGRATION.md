# Adding VPN Integration to Setup Wizard

## Changes Needed to `/setup-wizard/index.html`

### 1. Update Progress Bar

**Change from 4 steps to 6 steps:**

```html
<!-- OLD -->
<div class="progress-bar">
    <div class="progress-step completed"></div>
    <div class="progress-step"></div>
    <div class="progress-step"></div>
    <div class="progress-step"></div>
</div>

<!-- NEW -->
<div class="progress-bar">
    <div class="progress-step completed"></div>
    <div class="progress-step"></div>
    <div class="progress-step"></div>
    <div class="progress-step"></div>  <!-- New: VPN yes/no -->
    <div class="progress-step"></div>  <!-- New: VPN config -->
    <div class="progress-step"></div>
</div>
```

### 2. Add New Steps After Step 3

Insert these two steps between Step 3 (Security Settings) and Step 4 (Complete):

#### Step 4: VPN Question

```html
<!-- Step 4: VPN Integration (New) -->
<div class="step" id="step4">
    <h2>VPN Integration</h2>
    <p>Do you have a VPN subscription? HomeGuard can route all your network traffic through it.</p>

    <div class="info-box">
        <p><strong>Benefits of VPN integration:</strong></p>
        <ul class="feature-list">
            <li>Protect all devices automatically (no per-device setup)</li>
            <li>Works with IoT devices that can't run VPN apps</li>
            <li>One-time configuration</li>
            <li>Change servers easily from dashboard</li>
        </ul>
    </div>

    <div class="form-group">
        <label>Do you have a VPN subscription?</label>
        <select id="hasVPN" onchange="toggleVPNSteps()">
            <option value="no" selected>No, skip VPN setup</option>
            <option value="yes">Yes, I want to configure my VPN</option>
        </select>
    </div>

    <div class="wizard-buttons">
        <button class="btn-prev" onclick="prevStep(4)">← Back</button>
        <button class="btn-next" onclick="nextStep(4)">Next →</button>
    </div>
</div>
```

#### Step 5: VPN Configuration

```html
<!-- Step 5: VPN Provider Selection (New) -->
<div class="step" id="step5">
    <h2>Select VPN Provider</h2>
    <p>Choose your VPN provider from the list below.</p>

    <div class="form-group">
        <label for="vpnProvider">VPN Provider</label>
        <select id="vpnProvider" onchange="showVPNCredentials()">
            <option value="">-- Select Provider --</option>
            <option value="nordvpn">NordVPN</option>
            <option value="mullvad">Mullvad</option>
            <option value="protonvpn">ProtonVPN</option>
            <option value="surfshark">Surfshark</option>
            <option value="pia">Private Internet Access (PIA)</option>
            <option value="expressvpn">ExpressVPN</option>
            <option value="other">Other (Manual Config)</option>
        </select>
    </div>

    <div id="vpnCredentialsForm" style="display: none; margin-top: 20px;">
        <!-- Dynamic form populated by showVPNCredentials() -->
    </div>

    <div class="info-box" style="margin-top: 20px;">
        <p><strong>🔒 Security Note:</strong> Your credentials are stored locally on HomeGuard and never sent anywhere else.</p>
    </div>

    <div class="wizard-buttons">
        <button class="btn-prev" onclick="prevStep(5)">← Back</button>
        <button class="btn-next" onclick="nextStep(5)">Next →</button>
    </div>
</div>
```

### 3. Rename Old Step 4 to Step 6

```html
<!-- Step 6: Complete (was Step 4) -->
<div class="step" id="step6">
    <div class="success-icon">✅</div>
    <h2 style="text-align: center;">Setup Complete!</h2>
    <!-- rest of completion step -->
</div>
```

### 4. Add JavaScript Functions

Add these functions to the existing `<script>` section:

```javascript
// VPN Configuration State
let vpnEnabled = false;

function toggleVPNSteps() {
    vpnEnabled = document.getElementById('hasVPN').value === 'yes';
}

function showVPNCredentials() {
    const provider = document.getElementById('vpnProvider').value;
    const form = document.getElementById('vpnCredentialsForm');

    if (!provider) {
        form.style.display = 'none';
        return;
    }

    const credentialForms = {
        nordvpn: `
            <div class="form-group">
                <label>NordVPN Username</label>
                <input type="text" id="vpn_username" placeholder="Your NordVPN username" required>
            </div>
            <div class="form-group">
                <label>NordVPN Password</label>
                <input type="password" id="vpn_password" placeholder="Your NordVPN password" required>
            </div>
        `,
        mullvad: `
            <div class="form-group">
                <label>Mullvad Account Number</label>
                <input type="text" id="vpn_account" placeholder="16-digit account number" required pattern="[0-9]{16}">
                <p style="font-size: 0.9em; color: #666; margin-top: 5px;">Example: 1234567890123456</p>
            </div>
        `,
        protonvpn: `
            <div class="form-group">
                <label>ProtonVPN Username</label>
                <input type="text" id="vpn_username" placeholder="Your ProtonVPN username" required>
            </div>
            <div class="form-group">
                <label>ProtonVPN Password</label>
                <input type="password" id="vpn_password" placeholder="Your ProtonVPN password" required>
            </div>
        `,
        surfshark: `
            <div class="form-group">
                <label>Surfshark Username</label>
                <input type="text" id="vpn_username" placeholder="Your Surfshark username" required>
            </div>
            <div class="form-group">
                <label>Surfshark Password</label>
                <input type="password" id="vpn_password" placeholder="Your Surfshark password" required>
            </div>
        `,
        pia: `
            <div class="form-group">
                <label>PIA Username</label>
                <input type="text" id="vpn_username" placeholder="Your PIA username" required>
            </div>
            <div class="form-group">
                <label>PIA Password</label>
                <input type="password" id="vpn_password" placeholder="Your PIA password" required>
            </div>
        `,
        expressvpn: `
            <div class="form-group">
                <label>ExpressVPN Activation Code</label>
                <input type="text" id="vpn_activation" placeholder="Your activation code" required>
                <p style="font-size: 0.9em; color: #666; margin-top: 5px;">Found in your ExpressVPN account</p>
            </div>
        `,
        other: `
            <div class="form-group">
                <label>Configuration File</label>
                <input type="file" id="vpn_config_file" accept=".ovpn,.conf" required>
                <p style="font-size: 0.9em; color: #666; margin-top: 5px;">Upload your OpenVPN (.ovpn) or WireGuard (.conf) config file</p>
            </div>
        `
    };

    form.innerHTML = credentialForms[provider] || '';
    form.style.display = 'block';
}

// Update the nextStep function to handle VPN skip logic
function nextStep(step) {
    // ... existing validation code ...

    // Handle VPN skip
    if (step === 4 && !vpnEnabled) {
        // Skip VPN configuration step
        document.getElementById('step' + currentStep).classList.remove('active');
        currentStep = 6; // Jump to completion
        document.getElementById('step' + currentStep).classList.add('active');
        updateProgressBar();
        return;
    }

    // Handle VPN provider validation
    if (step === 5) {
        const provider = document.getElementById('vpnProvider').value;
        if (!provider) {
            showError('VPN Provider Required', 'Please select your VPN provider or go back and choose "No" to skip VPN setup.');
            return;
        }

        // Validate credentials based on provider
        // ... validation logic ...
    }

    // ... rest of existing nextStep logic ...
}

// Update prevStep to handle VPN skip
function prevStep(step) {
    if (step === 6 && !vpnEnabled) {
        // Skip back over VPN configuration
        document.getElementById('step' + currentStep).classList.remove('active');
        currentStep = 4;
        document.getElementById('step' + currentStep).classList.add('active');
        updateProgressBar();
        return;
    }

    // ... rest of existing prevStep logic ...
}
```

### 5. Update saveSettings Function

```javascript
function saveSettings() {
    const settings = {
        // ... existing settings ...
        hasVPN: vpnEnabled,
        vpnProvider: vpnEnabled ? document.getElementById('vpnProvider').value : null,
        vpnCredentials: vpnEnabled ? gatherVPNCredentials() : null
    };

    // ... rest of saveSettings ...
}

function gatherVPNCredentials() {
    const provider = document.getElementById('vpnProvider').value;
    const credentials = {};

    // Gather credentials based on provider
    const usernameEl = document.getElementById('vpn_username');
    const passwordEl = document.getElementById('vpn_password');
    const accountEl = document.getElementById('vpn_account');
    const activationEl = document.getElementById('vpn_activation');
    const configFileEl = document.getElementById('vpn_config_file');

    if (usernameEl) credentials.username = usernameEl.value;
    if (passwordEl) credentials.password = passwordEl.value;
    if (accountEl) credentials.account = accountEl.value;
    if (activationEl) credentials.activation = activationEl.value;
    if (configFileEl && configFileEl.files.length > 0) {
        credentials.config_file = configFileEl.files[0].name;
        // In production, would upload file to backend
    }

    return credentials;
}
```

### 6. Update Completion Step to Show VPN Status

```javascript
// In the completion step (step6), add conditional VPN message
<div id="vpnCompletionMessage" style="display: none;" class="info-box">
    <p><strong>✓ VPN Configured:</strong> All network traffic is now routed through your VPN provider. All devices are protected automatically!</p>
</div>

// In JavaScript, show VPN message if configured
if (vpnEnabled) {
    document.getElementById('vpnCompletionMessage').style.display = 'block';
}
```

---

## Implementation Notes

1. **Optional Nature:** Users can select "No" at step 4 and skip entirely
2. **Provider-Specific Forms:** Each VPN provider gets customized credential form
3. **Step Skipping:** If VPN disabled, wizard jumps from step 4 → step 6
4. **Validation:** Ensures provider selected and credentials entered if VPN enabled
5. **Backend Integration:** Settings saved to localStorage (replace with API call in production)

---

## Backend API Endpoint Needed

The wizard should POST to `/api/setup` with:

```json
{
  "adminPassword": "...",
  "protectionLevel": "standard",
  "hasVPN": true,
  "vpnProvider": "mullvad",
  "vpnCredentials": {
    "account": "1234567890123456"
  }
}
```

Backend script (`/opt/homeguard/api/setup.sh`) should:
1. Configure Pi-hole with admin password
2. Set protection level (add appropriate blocklists)
3. If VPN enabled, call provider-specific setup script
4. Enable transparent gateway
5. Return success with IP address

---

## This Makes Setup User-Friendly!

✅ No terminal commands needed
✅ Beautiful GUI with clear steps
✅ VPN is optional (skip if not needed)
✅ Supports all major VPN providers
✅ Error handling and validation
✅ Mobile-responsive design

Users just:
1. Flash Pi OS
2. Boot Pi
3. Visit `http://homeguard.local/setup`
4. Click through wizard
5. Done!
