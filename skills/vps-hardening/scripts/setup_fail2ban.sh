#!/bin/bash
# Setup fail2ban with secure defaults
# Usage: sudo ./setup_fail2ban.sh [SSH_PORT]
# Example: sudo ./setup_fail2ban.sh 2222

set -euo pipefail

SSH_PORT="${1:-22}"
JAIL_LOCAL="/etc/fail2ban/jail.local"

echo "=== Fail2ban Setup ==="

# Ensure fail2ban is installed
if ! command -v fail2ban-client &>/dev/null; then
    echo "Installing fail2ban..."
    apt install -y fail2ban
fi

echo "[1/3] Creating jail configuration..."
cat > "$JAIL_LOCAL" << EOF
[DEFAULT]
# Ban duration: 1 hour
bantime = 3600

# Detection window: 10 minutes
findtime = 600

# Max retries before ban
maxretry = 5

# Ignore local IPs
ignoreip = 127.0.0.1/8 ::1

# Action: ban IP via UFW
banaction = ufw

[sshd]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[sshd-aggressive]
enabled = true
port = $SSH_PORT
filter = sshd[mode=aggressive]
logpath = /var/log/auth.log
maxretry = 3
bantime = 86400
EOF

echo "[2/3] Restarting fail2ban..."
systemctl enable fail2ban
systemctl restart fail2ban

echo "[3/3] Verifying status..."
sleep 2
fail2ban-client status

echo ""
echo "✅ Fail2ban configured"
echo "   SSH port: $SSH_PORT"
echo "   Ban time: 1 hour (standard) / 24 hours (aggressive)"
echo "   Max retries: 3"
echo ""
echo "Useful commands:"
echo "   fail2ban-client status sshd    # Check SSH jail"
echo "   fail2ban-client unban IP       # Unban an IP"
