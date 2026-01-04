#!/bin/bash
# Verify SSH connectivity for a user before critical operations
# Usage: ./verify_ssh.sh USERNAME [SSH_PORT]
# Example: ./verify_ssh.sh deploy 22
#
# This script verifies:
# 1. User exists and has a home directory
# 2. SSH authorized_keys file exists and has correct permissions
# 3. User is in sudo group
# 4. SSH service is running
# 5. SSH port is listening

set -euo pipefail

USERNAME="${1:-}"
SSH_PORT="${2:-22}"

if [[ -z "$USERNAME" ]]; then
    echo "Usage: ./verify_ssh.sh USERNAME [SSH_PORT]"
    echo "Example: ./verify_ssh.sh deploy 22"
    exit 1
fi

echo "=== SSH Connectivity Verification ==="
echo "User: $USERNAME"
echo "Port: $SSH_PORT"
echo ""

ERRORS=0

# Check 1: User exists
echo -n "[1/6] User exists... "
if id "$USERNAME" &>/dev/null; then
    echo "✅"
else
    echo "❌ User $USERNAME does not exist"
    ERRORS=$((ERRORS + 1))
fi

# Check 2: Home directory exists
echo -n "[2/6] Home directory... "
HOME_DIR="/home/$USERNAME"
if [[ -d "$HOME_DIR" ]]; then
    echo "✅ $HOME_DIR"
else
    echo "❌ $HOME_DIR does not exist"
    ERRORS=$((ERRORS + 1))
fi

# Check 3: SSH directory and authorized_keys
echo -n "[3/6] SSH authorized_keys... "
SSH_DIR="$HOME_DIR/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"
if [[ -f "$AUTH_KEYS" ]]; then
    KEY_COUNT=$(wc -l < "$AUTH_KEYS" 2>/dev/null || echo "0")
    if [[ "$KEY_COUNT" -gt 0 ]]; then
        echo "✅ ($KEY_COUNT key(s))"
    else
        echo "❌ File exists but is empty"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "❌ $AUTH_KEYS not found"
    ERRORS=$((ERRORS + 1))
fi

# Check 4: Permissions
echo -n "[4/6] SSH permissions... "
PERM_OK=true
if [[ -d "$SSH_DIR" ]]; then
    DIR_PERM=$(stat -c %a "$SSH_DIR" 2>/dev/null || stat -f %A "$SSH_DIR" 2>/dev/null)
    if [[ "$DIR_PERM" != "700" ]]; then
        PERM_OK=false
    fi
fi
if [[ -f "$AUTH_KEYS" ]]; then
    FILE_PERM=$(stat -c %a "$AUTH_KEYS" 2>/dev/null || stat -f %A "$AUTH_KEYS" 2>/dev/null)
    if [[ "$FILE_PERM" != "600" ]]; then
        PERM_OK=false
    fi
fi
if $PERM_OK; then
    echo "✅ (.ssh=700, authorized_keys=600)"
else
    echo "⚠️  Permissions may be incorrect (should be .ssh=700, authorized_keys=600)"
fi

# Check 5: User in sudo group
echo -n "[5/6] Sudo access... "
if groups "$USERNAME" 2>/dev/null | grep -qE '\b(sudo|wheel)\b'; then
    echo "✅"
else
    echo "⚠️  User not in sudo group (may be intentional)"
fi

# Check 6: SSH service and port
echo -n "[6/6] SSH service on port $SSH_PORT... "
# Detect SSH service name
if systemctl list-units --type=service 2>/dev/null | grep -q "ssh.service"; then
    SSH_SERVICE="ssh"
elif systemctl list-units --type=service 2>/dev/null | grep -q "sshd.service"; then
    SSH_SERVICE="sshd"
else
    SSH_SERVICE="ssh"
fi

if systemctl is-active --quiet "$SSH_SERVICE" 2>/dev/null; then
    # Check if port is listening
    if ss -tlnp 2>/dev/null | grep -q ":$SSH_PORT "; then
        echo "✅ ($SSH_SERVICE active, port listening)"
    elif netstat -tlnp 2>/dev/null | grep -q ":$SSH_PORT "; then
        echo "✅ ($SSH_SERVICE active, port listening)"
    else
        echo "⚠️  Service running but port $SSH_PORT may not be listening"
    fi
else
    echo "❌ SSH service not running"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "════════════════════════════════════════"

if [[ $ERRORS -eq 0 ]]; then
    echo "✅ All critical checks passed!"
    echo ""
    echo "You should be able to connect with:"
    echo "  ssh -p $SSH_PORT $USERNAME@<server_ip>"
    echo ""
    echo "Test this from ANOTHER terminal before:"
    echo "  - Disabling root login"
    echo "  - Disabling password authentication"
    echo "  - Enabling the firewall"
    exit 0
else
    echo "❌ $ERRORS critical error(s) found!"
    echo ""
    echo "Fix these issues before proceeding with SSH hardening"
    echo "or you may lock yourself out of the server."
    exit 1
fi
