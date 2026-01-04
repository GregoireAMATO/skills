# Basic VPS Monitoring

## Option 1: Simple Script Monitoring

Create `/usr/local/bin/server-health.sh`:

```bash
#!/bin/bash
echo "=== Server Health Report ==="
echo "Date: $(date)"
echo ""
echo "=== Uptime ==="
uptime
echo ""
echo "=== Disk Usage ==="
df -h / | tail -1
echo ""
echo "=== Memory ==="
free -h | grep Mem
echo ""
echo "=== Load Average ==="
cat /proc/loadavg
echo ""
echo "=== Failed SSH Attempts (last 24h) ==="
grep "Failed password" /var/log/auth.log | tail -5
echo ""
echo "=== Fail2ban Status ==="
fail2ban-client status sshd 2>/dev/null || echo "fail2ban not running"
```

Add to cron for daily reports:
```bash
0 8 * * * /usr/local/bin/server-health.sh | mail -s "Server Health" admin@example.com
```

## Option 2: Netdata (Real-time Dashboard)

```bash
# One-line install
bash <(curl -Ss https://my-netdata.io/kickstart.sh)

# Access at http://server-ip:19999
# Restrict access via firewall or nginx proxy
```

## Option 3: Logwatch (Daily Log Summary)

```bash
apt install -y logwatch

# Configure
cat > /etc/logwatch/conf/logwatch.conf << EOF
Output = mail
MailTo = admin@example.com
MailFrom = logwatch@server
Detail = Med
EOF

# Test
logwatch --output stdout --detail Med
```

## Essential Logs to Monitor

| Log | Purpose |
|-----|---------|
| `/var/log/auth.log` | Authentication attempts |
| `/var/log/fail2ban.log` | Banned IPs |
| `/var/log/ufw.log` | Firewall blocks |
| `/var/log/syslog` | System events |
| `/var/log/nginx/access.log` | Web traffic |
| `/var/log/nginx/error.log` | Web errors |

## Quick Log Commands

```bash
# Recent failed logins
grep "Failed" /var/log/auth.log | tail -20

# Banned IPs
fail2ban-client status sshd

# Firewall blocks
grep "UFW BLOCK" /var/log/ufw.log | tail -20

# Disk space alerts
df -h | awk '$5 > "80%" {print}'
```
