#!/bin/bash
# Setup unattended-upgrades for automatic security updates
# Usage: sudo ./setup_unattended.sh [EMAIL]
# Example: sudo ./setup_unattended.sh admin@example.com

set -euo pipefail

EMAIL="${1:-}"

echo "=== Automatic Updates Setup ==="

# Ensure packages are installed
if ! dpkg -l | grep -q unattended-upgrades; then
    echo "Installing unattended-upgrades..."
    apt install -y unattended-upgrades apt-listchanges
fi

echo "[1/3] Configuring auto-upgrades..."
cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Download-Upgradeable-Packages "1";
EOF

echo "[2/3] Configuring unattended-upgrades..."
cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}";
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};

Unattended-Upgrade::Package-Blacklist {
};

Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "04:00";
EOF

# Add email notification if provided
if [[ -n "$EMAIL" ]]; then
    echo "Unattended-Upgrade::Mail \"$EMAIL\";" >> /etc/apt/apt.conf.d/50unattended-upgrades
    echo "Unattended-Upgrade::MailReport \"on-change\";" >> /etc/apt/apt.conf.d/50unattended-upgrades
    echo "   Email notifications: $EMAIL"
fi

echo "[3/3] Enabling service..."
systemctl enable unattended-upgrades
systemctl restart unattended-upgrades

echo ""
echo "✅ Automatic updates configured"
echo "   Security updates: enabled"
echo "   Auto-reboot: disabled (manual reboot recommended)"
echo ""
echo "Test with: unattended-upgrades --dry-run --debug"
