#!/bin/bash
# Setup UFW firewall with secure defaults
# Usage: sudo ./setup_firewall.sh [SSH_PORT] [EXTRA_PORTS...]
# Example: sudo ./setup_firewall.sh 2222 80 443

set -euo pipefail

SSH_PORT="${1:-22}"
shift || true
EXTRA_PORTS=("$@")

echo "=== Firewall Setup (UFW) ==="

# Reset UFW to defaults
echo "[1/5] Resetting UFW..."
ufw --force reset

# Set default policies
echo "[2/5] Setting default policies..."
ufw default deny incoming
ufw default allow outgoing

# Allow SSH
echo "[3/5] Allowing SSH on port $SSH_PORT..."
ufw allow "$SSH_PORT/tcp" comment 'SSH'

# Allow extra ports
if [[ ${#EXTRA_PORTS[@]} -gt 0 ]]; then
    echo "[4/5] Allowing extra ports..."
    for port in "${EXTRA_PORTS[@]}"; do
        if [[ "$port" =~ ^[0-9]+$ ]]; then
            ufw allow "$port/tcp" comment "Custom port $port"
            echo "   Allowed: $port/tcp"
        fi
    done
else
    echo "[4/5] No extra ports specified (skipped)"
fi

# Enable UFW
echo "[5/5] Enabling firewall..."
ufw --force enable

echo ""
echo "✅ Firewall configured"
ufw status verbose
