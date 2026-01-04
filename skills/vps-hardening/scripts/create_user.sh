#!/bin/bash
# Create a sudo user with SSH key authentication
# Usage: sudo ./create_user.sh USERNAME [SSH_PUBLIC_KEY]
# Example: sudo ./create_user.sh deploy "ssh-rsa AAAA..."

set -euo pipefail

USERNAME="${1:-}"
SSH_KEY="${2:-}"

if [[ -z "$USERNAME" ]]; then
    echo "Error: Username required"
    echo "Usage: sudo ./create_user.sh USERNAME [SSH_PUBLIC_KEY]"
    exit 1
fi

echo "=== Creating User: $USERNAME ==="

# Check if user exists
if id "$USERNAME" &>/dev/null; then
    echo "User $USERNAME already exists"
else
    echo "[1/3] Creating user..."
    adduser --disabled-password --gecos "" "$USERNAME"
    usermod -aG sudo "$USERNAME"
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USERNAME"
    chmod 440 "/etc/sudoers.d/$USERNAME"
fi

# Setup SSH key if provided
if [[ -n "$SSH_KEY" ]]; then
    echo "[2/3] Setting up SSH key..."
    SSH_DIR="/home/$USERNAME/.ssh"
    mkdir -p "$SSH_DIR"
    echo "$SSH_KEY" >> "$SSH_DIR/authorized_keys"
    chmod 700 "$SSH_DIR"
    chmod 600 "$SSH_DIR/authorized_keys"
    chown -R "$USERNAME:$USERNAME" "$SSH_DIR"
    echo "   SSH key added"
else
    echo "[2/3] No SSH key provided (skipped)"
fi

echo "[3/3] Verifying..."
echo "   User: $USERNAME"
echo "   Groups: $(groups $USERNAME)"
echo "   Home: /home/$USERNAME"

echo "✅ User $USERNAME created successfully"
