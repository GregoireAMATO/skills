#!/bin/bash
# Setup UFW firewall with secure defaults and safety timer
# Usage: sudo ./setup_firewall.sh [SSH_PORT] [EXTRA_PORTS...]
# Example: sudo ./setup_firewall.sh 2222 80 443
#
# SAFETY FEATURE: After enabling UFW, a 120-second safety timer starts.
# If you don't confirm within 120s, UFW auto-disables to prevent lockout.

set -euo pipefail

SSH_PORT="${1:-22}"
shift || true
EXTRA_PORTS=("$@")

SAFETY_TIMEOUT=120
CONFIRM_FILE="/tmp/ufw_confirmed_$$"
ROLLBACK_SCRIPT="/tmp/ufw_rollback_$$.sh"

echo "=== Firewall Setup (UFW) with Safety Timer ==="

# Create rollback script
cat > "$ROLLBACK_SCRIPT" << 'ROLLBACK_EOF'
#!/bin/bash
CONFIRM_FILE="$1"
TIMEOUT="$2"

sleep "$TIMEOUT"

if [[ ! -f "$CONFIRM_FILE" ]]; then
    echo ""
    echo "⚠️  Safety timeout reached! No confirmation received."
    echo "🔓 Disabling UFW to prevent lockout..."
    ufw --force disable
    echo "✅ UFW disabled. You can re-run setup_firewall.sh to try again."
fi

rm -f "$CONFIRM_FILE" 2>/dev/null || true
rm -f "$0" 2>/dev/null || true
ROLLBACK_EOF
chmod +x "$ROLLBACK_SCRIPT"

# Reset UFW to defaults
echo "[1/6] Resetting UFW..."
ufw --force reset

# Set default policies
echo "[2/6] Setting default policies..."
ufw default deny incoming
ufw default allow outgoing

# Allow SSH
echo "[3/6] Allowing SSH on port $SSH_PORT..."
ufw allow "$SSH_PORT/tcp" comment 'SSH'

# Allow extra ports
if [[ ${#EXTRA_PORTS[@]} -gt 0 ]]; then
    echo "[4/6] Allowing extra ports..."
    for port in "${EXTRA_PORTS[@]}"; do
        if [[ "$port" =~ ^[0-9]+$ ]]; then
            ufw allow "$port/tcp" comment "Custom port $port"
            echo "   Allowed: $port/tcp"
        fi
    done
else
    echo "[4/6] No extra ports specified (skipped)"
fi

# Show rules before enabling
echo ""
echo "Rules to be applied:"
ufw status verbose 2>/dev/null || ufw show added

# Enable UFW
echo ""
echo "[5/6] Enabling firewall..."
ufw --force enable

# Start safety timer in background
echo "[6/6] Starting ${SAFETY_TIMEOUT}s safety timer..."
nohup bash "$ROLLBACK_SCRIPT" "$CONFIRM_FILE" "$SAFETY_TIMEOUT" > /dev/null 2>&1 &
ROLLBACK_PID=$!

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║  🔥 UFW ENABLED - SAFETY TIMER ACTIVE (${SAFETY_TIMEOUT}s)                      ║"
echo "║                                                                    ║"
echo "║  1. Open a NEW terminal NOW                                        ║"
echo "║  2. Test SSH: ssh -p $SSH_PORT <user>@<server_ip>                  ║"
echo "║  3. If it works, run this command to confirm:                      ║"
echo "║                                                                    ║"
echo "║     sudo touch $CONFIRM_FILE                                       ║"
echo "║                                                                    ║"
echo "║  ⚠️  If you don't confirm in ${SAFETY_TIMEOUT}s, UFW will AUTO-DISABLE!         ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Waiting for confirmation..."

# Wait for confirmation or timeout
ELAPSED=0
while [[ $ELAPSED -lt $SAFETY_TIMEOUT ]]; do
    if [[ -f "$CONFIRM_FILE" ]]; then
        rm -f "$CONFIRM_FILE"
        kill $ROLLBACK_PID 2>/dev/null || true
        rm -f "$ROLLBACK_SCRIPT" 2>/dev/null || true
        echo ""
        echo "✅ Firewall confirmed and active!"
        ufw status verbose
        exit 0
    fi
    sleep 5
    ELAPSED=$((ELAPSED + 5))
    REMAINING=$((SAFETY_TIMEOUT - ELAPSED))
    if [[ $REMAINING -gt 0 ]]; then
        echo "   ⏳ ${REMAINING}s remaining... (run: sudo touch $CONFIRM_FILE)"
    fi
done

# If we get here, timeout occurred
echo ""
echo "⚠️  Timeout! UFW has been disabled for safety."
echo "   Re-run this script to try again."
