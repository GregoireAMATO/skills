---
name: vps-hardening
description: Secure and harden a fresh VPS (Ubuntu/Debian). Use when setting up a new server, securing SSH, configuring firewalls, or implementing server security best practices. Covers initial setup, user creation, SSH hardening, UFW firewall, fail2ban, and automatic updates.
---

# VPS Hardening

Secure a fresh Ubuntu/Debian VPS with battle-tested security configurations.

## Workflow Overview

1. **Initial setup** → Update system, set timezone, install essentials
2. **Create user** → Non-root sudo user with SSH key
3. **Harden SSH** → Disable root/password, change port
4. **Firewall** → UFW with minimal open ports
5. **Fail2ban** → Auto-ban brute force attempts
6. **Auto-updates** → Unattended security upgrades

⚠️ **Critical**: Complete steps 1-3 before step 4 to avoid lockout.

## Scripts

All scripts are idempotent and require root/sudo. Copy to VPS and run.

| Script | Purpose | Usage |
|--------|---------|-------|
| `initial_setup.sh` | System updates, packages | `sudo ./initial_setup.sh [TIMEZONE]` |
| `create_user.sh` | Create sudo user | `sudo ./create_user.sh USERNAME [SSH_KEY]` |
| `harden_ssh.sh` | Secure SSH config | `sudo ./harden_ssh.sh [PORT]` |
| `setup_firewall.sh` | Configure UFW | `sudo ./setup_firewall.sh [SSH_PORT] [EXTRA_PORTS...]` |
| `setup_fail2ban.sh` | Install fail2ban | `sudo ./setup_fail2ban.sh [SSH_PORT]` |
| `setup_unattended.sh` | Auto security updates | `sudo ./setup_unattended.sh [EMAIL]` |

## Typical Usage

```bash
# 1. Initial setup
sudo ./initial_setup.sh Europe/Paris

# 2. Create deploy user with SSH key
sudo ./create_user.sh deploy "ssh-rsa AAAA..."

# 3. Harden SSH (use custom port 2222)
sudo ./harden_ssh.sh 2222

# ⚠️ TEST LOGIN IN NEW TERMINAL BEFORE CONTINUING
# ssh -p 2222 deploy@server

# 4. Setup firewall (SSH + HTTP + HTTPS)
sudo ./setup_firewall.sh 2222 80 443

# 5. Setup fail2ban
sudo ./setup_fail2ban.sh 2222

# 6. Enable auto-updates
sudo ./setup_unattended.sh admin@example.com
```

## References

- **[checklist.md](references/checklist.md)** — Security verification checklist
- **[nginx-ssl.md](references/nginx-ssl.md)** — Nginx + Let's Encrypt setup
- **[monitoring.md](references/monitoring.md)** — Basic server monitoring options

## Key Security Settings Applied

**SSH** (`/etc/ssh/sshd_config`):
- Root login: disabled
- Password auth: disabled
- Max auth tries: 3
- Key-only authentication

**Firewall** (UFW):
- Default deny incoming
- Default allow outgoing
- Only specified ports open

**Fail2ban**:
- 3 failed attempts → 1 hour ban
- Aggressive mode → 24 hour ban
- UFW integration

## Lockout Recovery

If locked out, use provider's console/VNC access to:
1. Login as root via console
2. Fix `/etc/ssh/sshd_config`
3. Restart SSH: `systemctl restart sshd`
4. Check UFW: `ufw status` / `ufw disable`
