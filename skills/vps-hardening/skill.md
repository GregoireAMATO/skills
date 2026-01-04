---
name: vps-hardening
description: Secure and harden a fresh VPS (Ubuntu/Debian). Use when setting up a new server, securing SSH, configuring firewalls, or implementing server security best practices. Covers initial setup, user creation, SSH hardening, UFW firewall, fail2ban, and automatic updates.
---

# VPS Hardening

Secure a fresh Ubuntu/Debian VPS with battle-tested security configurations.

## Safety Features

This skill includes anti-lockout protections:

- **SSH service detection**: Automatically detects `ssh` (Ubuntu) vs `sshd` (other distros)
- **UFW safety timer**: 120-second auto-rollback if connection not confirmed
- **Verification script**: Pre-flight checks before critical operations
- **Backup configs**: All modified configs are backed up with timestamps

## Workflow Overview

```
1. initial_setup.sh      → Paquets de base
2. create_user.sh        → Créer utilisateur + clé SSH
3. verify_ssh.sh         → Vérifier configuration SSH
4. ⚠️  STOP : Tester connexion nouvel utilisateur depuis AUTRE terminal
5. harden_ssh.sh         → Durcir SSH (désactiver root/password)
6. ⚠️  STOP : Re-tester connexion depuis AUTRE terminal
7. setup_firewall.sh     → Activer UFW (avec timer de sécurité 120s)
8. setup_fail2ban.sh     → Protection brute-force
9. setup_unattended.sh   → Mises à jour auto
```

## Scripts

All scripts are idempotent and require root/sudo.

| Script | Purpose | Usage |
|--------|---------|-------|
| `initial_setup.sh` | System updates, packages | `sudo ./initial_setup.sh [TIMEZONE]` |
| `create_user.sh` | Create sudo user | `sudo ./create_user.sh USERNAME [SSH_KEY]` |
| `verify_ssh.sh` | **NEW** Pre-flight SSH checks | `sudo ./verify_ssh.sh USERNAME [PORT]` |
| `harden_ssh.sh` | Secure SSH config | `sudo ./harden_ssh.sh [PORT]` |
| `setup_firewall.sh` | Configure UFW (with safety timer) | `sudo ./setup_firewall.sh [SSH_PORT] [EXTRA_PORTS...]` |
| `setup_fail2ban.sh` | Install fail2ban | `sudo ./setup_fail2ban.sh [SSH_PORT]` |
| `setup_unattended.sh` | Auto security updates | `sudo ./setup_unattended.sh [EMAIL]` |

## Typical Usage

```bash
# 1. Initial setup
sudo ./initial_setup.sh Europe/Paris

# 2. Create deploy user with SSH key
sudo ./create_user.sh deploy "ssh-ed25519 AAAA..."

# 3. Verify SSH is properly configured
sudo ./verify_ssh.sh deploy 22

# ⚠️ CRITICAL: TEST LOGIN IN NEW TERMINAL BEFORE CONTINUING
# ssh deploy@server

# 4. Harden SSH (keep port 22 or use custom port)
sudo ./harden_ssh.sh 22

# ⚠️ CRITICAL: TEST LOGIN AGAIN IN NEW TERMINAL
# ssh deploy@server

# 5. Setup firewall (SSH + HTTP + HTTPS)
# NOTE: This has a 120s safety timer - you must confirm!
sudo ./setup_firewall.sh 22 80 443
# When prompted, run in another terminal: sudo touch /tmp/ufw_confirmed_<PID>

# 6. Setup fail2ban
sudo ./setup_fail2ban.sh 22

# 7. Enable auto-updates
sudo ./setup_unattended.sh admin@example.com
```

## UFW Safety Timer

The firewall script now includes a **120-second safety timer**:

1. UFW is enabled with your rules
2. A countdown starts (120 seconds)
3. You must test SSH from another terminal
4. If it works, run the confirmation command shown
5. If you don't confirm in time, **UFW auto-disables** to prevent lockout

```
╔════════════════════════════════════════════════════════════════════╗
║  🔥 UFW ENABLED - SAFETY TIMER ACTIVE (120s)                       ║
║                                                                    ║
║  1. Open a NEW terminal NOW                                        ║
║  2. Test SSH: ssh -p 22 deploy@server                              ║
║  3. If it works, run: sudo touch /tmp/ufw_confirmed_12345          ║
║                                                                    ║
║  ⚠️  If you don't confirm in 120s, UFW will AUTO-DISABLE!          ║
╚════════════════════════════════════════════════════════════════════╝
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
- **Safety timer for lockout prevention**

**Fail2ban**:
- 3 failed attempts → 1 hour ban
- Aggressive mode → 24 hour ban
- UFW integration

## Lockout Recovery

If locked out despite safety features, use provider's console/VNC access:

1. Login as root via console
2. Disable firewall: `ufw disable`
3. Fix SSH if needed:
   - Check config: `cat /etc/ssh/sshd_config`
   - Restore backup: `cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config`
4. Restart SSH: `systemctl restart ssh` (Ubuntu) or `systemctl restart sshd`
5. Test connection from external terminal
6. Re-enable firewall when ready: `ufw enable`
