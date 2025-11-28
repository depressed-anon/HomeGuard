# Contributing to HomeGuard Pro

Thank you for your interest in contributing to HomeGuard Pro! We welcome contributions from the community.

## How to Contribute

### 1. Fork the Repository

Click the "Fork" button at the top of this repository to create your own copy.

### 2. Clone Your Fork

```bash
git clone https://github.com/YOUR-USERNAME/homeguard-pro.git
cd homeguard-pro
```

### 3. Create a Branch

```bash
git checkout -b feature/your-feature-name
```

### 4. Make Your Changes

- Write clear, readable code
- Follow existing code style
- Test your changes thoroughly
- Update documentation if needed

### 5. Commit Your Changes

```bash
git add .
git commit -m "Description of your changes"
```

### 6. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

### 7. Open a Pull Request

Go to the original repository and click "New Pull Request"

---

## Contributor License Agreement

**By submitting a pull request, you agree to our [Contributor License Agreement (CLA)](CLA.md).**

This is automatic - no forms to sign. Just open a PR and you're agreeing to the CLA terms.

**Key points:**
- Your code stays MIT licensed (free and open)
- You keep copyright to your work
- You grant the project rights to use and distribute your contribution
- The project can offer commercial support (while keeping code free)

Read the full [CLA here](CLA.md).

---

## What to Contribute

### Good First Issues

Look for issues labeled `good first issue` - these are great for newcomers.

### Bug Fixes

Found a bug? Please:
1. Check if an issue already exists
2. If not, open an issue describing the bug
3. Submit a PR with the fix

### New Features

Want to add a feature? Please:
1. Open an issue to discuss it first
2. Wait for maintainer feedback
3. Submit a PR after discussion

### Documentation

Documentation improvements are always welcome:
- Fix typos
- Clarify instructions
- Add examples
- Improve README

### VPN Providers

We especially welcome contributions for additional VPN providers:
- Windscribe
- CyberGhost
- TorGuard
- IVPN
- AirVPN

See `scripts/vpn/providers/` for examples.

---

## Code Style

- **Scripts:** Use bash best practices (shellcheck clean)
- **Python:** Follow PEP 8
- **Documentation:** Use clear, simple language
- **Commit messages:** Be descriptive

---

## Testing

Before submitting a PR:

```bash
# Test installation script
sudo bash scripts/install-complete-transparent.sh --test

# Test VPN configuration
sudo bash scripts/vpn/configure-vpn.sh --provider mullvad --dry-run

# Check for syntax errors
shellcheck scripts/**/*.sh
```

---

## Questions?

- **General questions:** Open a GitHub issue
- **Security issues:** Email [maintainer email] (don't open public issue)
- **CLA questions:** See [CLA.md](CLA.md)

---

## Code of Conduct

Be respectful and constructive. We're all here to build something useful.

- ✅ Help others learn
- ✅ Give constructive feedback
- ✅ Focus on the code, not the person
- ❌ No harassment or discrimination
- ❌ No spam or self-promotion

---

## License

By contributing, you agree that your contributions will be licensed under the MIT License, subject to the terms in our [CLA](CLA.md).

---

**Thank you for contributing to HomeGuard Pro!** 🛡️
