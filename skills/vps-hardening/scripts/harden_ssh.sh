#!/bin/bash
# Harden SSH configuration
# Usage: sudo ./harden_ssh.sh [PORT]
# Example: sudo ./harden_ssh.sh 2222

set -euo pipefail

SSH_PORT="${1:-22}"
SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP_FILE="/etc/ssh/sshd_config.backup.$(date +%Y%m%d%H%M%S)"

echo "=== SSH Hardening ==="

# Backup original config
echo "[1/4] Backing up config to $BACKUP_FILE..."
cp "$SSHD_CONFIG" "$BACKUP_FILE"

# Function to set or update SSH config
set_ssh_config() {
    local key="$1"
    local value="$2"
    if grep -q "^#*${key}" "$SSHD_CONFIG"; then
        sed -i "s/^#*${key}.*/${key} ${value}/" "$SSHD_CONFIG"
    else
        echo "${key} ${value}" >> "$SSHD_CONFIG"
    fi
}

echo "[2/4] Applying secure configuration..."

# Core security settings
set_ssh_config "Port" "$SSH_PORT"
set_ssh_config "PermitRootLogin" "no"
set_ssh_config "PasswordAuthentication" "no"
set_ssh_config "PermitEmptyPasswords" "no"
set_ssh_config "PubkeyAuthentication" "yes"
set_ssh_config "AuthenticationMethods" "publickey"

# Hardening options
set_ssh_config "X11Forwarding" "no"
set_ssh_config "AllowAgentForwarding" "no"
set_ssh_config "AllowTcpForwarding" "no"
set_ssh_config "MaxAuthTries" "3"
set_ssh_config "MaxSessions" "2"
set_ssh_config "ClientAliveInterval" "300"
set_ssh_config "ClientAliveCountMax" "2"
set_ssh_config "LoginGraceTime" "30"

# Protocol settings
set_ssh_config "Protocol" "2"

echo "[3/4] Validating configuration..."
if sshd -t; then
    echo "   Configuration valid"
else
    echo "Error: Invalid configuration. Restoring backup..."
    cp "$BACKUP_FILE" "$SSHD_CONFIG"
    exit 1
fi

echo "[4/4] Restarting SSH service..."
systemctl restart sshd

echo ""
echo "✅ SSH hardening complete"
echo "   Port: $SSH_PORT"
echo "   Root login: disabled"
echo "   Password auth: disabled"
echo ""
echo "⚠️  IMPORTANT: Before disconnecting, verify you can login:"
echo "   ssh -p $SSH_PORT user@server"
