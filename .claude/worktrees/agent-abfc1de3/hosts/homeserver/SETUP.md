# Homeserver Setup Guide

Manual steps for setting up the Raspberry Pi 4B homeserver.

## Hardware

- Raspberry Pi 4B
- USB 3.0 SATA SSD adapter
- MicroSD card (temporary, for firmware update)

## Phase 1: Prepare Raspberry Pi for USB Boot

1. Flash Raspberry Pi OS Lite to SD card (temporary, for firmware update):
   ```bash
   # sudo is required for raw device access
   sudo dd if=raspios-lite.img of=/dev/sdX bs=4M status=progress conv=fsync
   ```

2. Boot Pi with SD card and update firmware:
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo rpi-eeprom-update -d -a
   ```

3. Enable USB boot:
   ```bash
   sudo raspi-config
   # Advanced Options -> Boot Order -> USB Boot
   ```

4. Reboot and remove SD card - Pi should attempt USB boot

## Phase 2: Build and Flash NixOS Image

1. Build SD image from thinkpad:
   ```bash
   nix build .#nixosConfigurations.homeserver.config.system.build.sdImage
   ```

2. Identify your USB SSD device:
   ```bash
   lsblk
   # Look for your SSD (e.g., /dev/sdX)
   ```

3. Flash to USB SSD:
   ```bash
   sudo dd if=result/sd-image/nixos-sd-image-*.img of=/dev/sdX bs=4M status=progress conv=fsync
   sync
   ```

## Phase 3: First Boot

1. Connect SSD to Pi and power on

2. Find Pi's IP address:
   ```bash
   # From router admin or:
   nmap -sn 192.168.1.0/24 | grep -B2 "Raspberry\|homeserver"
   # Or check router's DHCP leases
   ```

3. SSH to Pi:
   ```bash
   ssh piotr@<pi-ip>
   ```

## Phase 4: Router Configuration

1. Create DHCP reservation:
   - Log into router admin
   - Find homeserver's MAC address
   - Reserve a static IP (e.g., 192.168.1.10)

2. For devices using DNS ad-blocking:
   - Manually configure DNS to point to homeserver IP
   - Or set as secondary DNS in router

## Phase 5: Post-Installation Setup

Secrets (including the remote builder SSH key) are managed declaratively via sops-nix. No manual secret creation needed.

1. Verify secrets are decrypted:
   ```bash
   ls -la /run/secrets/
   ```

2. Verify services:
   ```bash
   systemctl status nextcloud-setup
   systemctl status home-assistant
   systemctl status blocky
   systemctl status paperless
   systemctl status calibre-server
   systemctl status tailscaled
   ```

3. Test remote builds:
   ```bash
   # On homeserver - should delegate to thinkpad
   nix build nixpkgs#hello --rebuild
   ```

4. Access web interfaces:
   - Nextcloud: https://nextcloud.homeserver.local
   - Home Assistant: https://hass.homeserver.local
   - Paperless: https://paperless.homeserver.local
   - Calibre: https://calibre.homeserver.local
   - Jellyfin: https://jellyfin.homeserver.local
   - Forgejo: https://forgejo.homeserver.local
   - Blocky API: https://blocky.homeserver.local

## Deploying Future Updates

### From thinkpad (recommended):
```bash
nixos-rebuild switch --flake ".#homeserver" \
  --target-host piotr@homeserver \
  --sudo
```

### From homeserver (uses remote build):
```bash
cd /path/to/nix-config
sudo nixos-rebuild switch --flake ".#homeserver"
```

## Service Ports

| Service                     | Port  |
|-----------------------------|-------|
| SSH                         | 22    |
| DNS (Blocky)                | 53    |
| HTTP (redirect to HTTPS)    | 80    |
| HTTPS (LAN + Tailscale)     | 443   |
| MPD                         | 6600  |
| Home Assistant (Tailscale)  | 8443  |
| Paperless (Tailscale)       | 8444  |
| Calibre (Tailscale)         | 8445  |
| Jellyfin (Tailscale)        | 8446  |
| Forgejo (Tailscale)         | 8447  |
| MPD HTTP stream             | 8600  |

## Verification Checklist

- [x] Pi boots from USB SSD
- [x] SSH access works: `ssh piotr@homeserver`
- [ ] Secrets decrypted: `ls /run/secrets/`
- [ ] Remote build works: builds happen on thinkpad
- [ ] Nextcloud accessible at https://nextcloud.homeserver.local
- [ ] Home Assistant accessible at https://hass.homeserver.local
- [ ] Paperless accessible at https://paperless.homeserver.local
- [ ] Calibre accessible at https://calibre.homeserver.local
- [ ] Jellyfin accessible at https://jellyfin.homeserver.local
- [ ] Forgejo accessible at https://forgejo.homeserver.local
- [ ] Blocky DNS responds: `dig @homeserver google.com`
- [ ] Ad blocking works: `dig @homeserver ads.google.com` returns 0.0.0.0
- [ ] Tailscale connected: `tailscale status`
- [ ] Services survive reboot

## Troubleshooting

### Remote builds not working
1. Verify thinkpad is reachable: `ping thinkpad-x1-g3.local`
2. Test SSH connection: `ssh -i /etc/nix/builder_key builder@thinkpad-x1-g3.local`
3. Check builder key permissions: `ls -la /etc/nix/builder_key` (should be 600)
4. Verify builder is trusted on thinkpad: check `nix.settings.trusted-users`

### Nextcloud not starting
1. Check if sops decrypted secrets: `ls -la /run/secrets/`
2. Check sops-nix service: `systemctl status sops-nix`
3. Check logs: `journalctl -u nextcloud-setup -f`
4. Check PostgreSQL: `systemctl status postgresql`

### DNS not working
1. Check Blocky status: `systemctl status blocky`
2. Test locally: `dig @127.0.0.1 google.com`
3. Check firewall: `sudo iptables -L -n | grep 53`

## Secrets Management

Secrets are managed via sops-nix and stored encrypted in the private repository.

### Editing Secrets

1. Set up admin age key (one-time):
   ```bash
   age-keygen -o ~/.config/sops/age/keys.txt
   export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
   # Add public key to nix-config-private/.sops.yaml
   ```

2. Edit secrets:
   ```bash
   cd ~/development/nix-config-private
   sops secrets/homeserver.yaml
   ```

### Adding Host Age Key

To get a host's age public key from its SSH host key:
```bash
cat /etc/ssh/ssh_host_ed25519_key.pub | nix-shell -p ssh-to-age --run ssh-to-age
```

Add the key to `nix-config-private/.sops.yaml` and re-encrypt secrets.

### Managed Secrets

| Secret | Description |
|--------|-------------|
| `nextcloud-admin-pass` | Nextcloud admin password |
| `paperless-admin-pass` | Paperless-ngx admin password |
| `builder-key` | SSH key for remote builds to thinkpad |
| `piotr-password-hash` | User login password hash |
| `tailscale-auth-key` | Tailscale authentication key |
| `homeserver-lan-cert` | mkcert wildcard TLS certificate for *.homeserver.local |
| `homeserver-lan-key` | mkcert wildcard TLS private key |
