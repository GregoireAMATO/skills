#!/bin/bash
# Initial VPS setup: updates, timezone, locale
# Usage: sudo ./initial_setup.sh [TIMEZONE]
# Example: sudo ./initial_setup.sh Europe/Paris

set -euo pipefail

TIMEZONE="${1:-UTC}"

echo "=== VPS Initial Setup ==="

# Update system
echo "[1/4] Updating system packages..."
apt update && apt upgrade -y

# Set timezone
echo "[2/4] Setting timezone to $TIMEZONE..."
timedatectl set-timezone "$TIMEZONE"

# Configure locale
echo "[3/4] Configuring locale..."
if ! locale -a | grep -q "en_US.utf8"; then
    locale-gen en_US.UTF-8
fi
update-locale LANG=en_US.UTF-8

# Install essential packages
echo "[4/4] Installing essential packages..."
apt install -y \
    curl \
    wget \
    git \
    htop \
    ufw \
    fail2ban \
    unattended-upgrades \
    apt-listchanges

echo "✅ Initial setup complete"
echo "   Timezone: $(timedatectl show --property=Timezone --value)"
