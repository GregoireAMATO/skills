# VPS Security Checklist

Use this checklist to verify all security measures are in place.

## Essential (Must Have)

- [ ] System updated (`apt update && apt upgrade`)
- [ ] Non-root sudo user created
- [ ] SSH key authentication configured
- [ ] SSH password authentication disabled
- [ ] SSH root login disabled
- [ ] Firewall enabled with minimal open ports
- [ ] Fail2ban installed and running
- [ ] Automatic security updates enabled

## Recommended

- [ ] SSH port changed from 22
- [ ] SSH MaxAuthTries set to 3 or less
- [ ] Timezone configured correctly
- [ ] Unused services disabled
- [ ] Log monitoring configured

## Web Server (if applicable)

- [ ] HTTPS enabled with valid certificate
- [ ] HTTP redirects to HTTPS
- [ ] Security headers configured (HSTS, CSP, etc.)
- [ ] Nginx/Apache running as non-root
- [ ] Web root permissions restricted

## Verification Commands

```bash
# Check SSH config
sudo sshd -T | grep -E "permitrootlogin|passwordauthentication|port"

# Check firewall status
sudo ufw status verbose

# Check fail2ban status
sudo fail2ban-client status

# Check listening ports
sudo ss -tulpn

# Check running services
systemctl list-units --type=service --state=running

# Check for pending security updates
sudo unattended-upgrades --dry-run
```

## Regular Maintenance

- Review logs weekly: `/var/log/auth.log`, `/var/log/fail2ban.log`
- Check for updates: `apt update && apt list --upgradable`
- Review open ports: `ss -tulpn`
- Check fail2ban bans: `fail2ban-client status sshd`
- Verify backups are working
