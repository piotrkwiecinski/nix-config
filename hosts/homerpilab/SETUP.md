# Homerpilab Setup Guide

Raspberry Pi 4B running NixOS from USB SSD.

## Prerequisites

- Raspberry Pi 4B with USB boot enabled (most units shipped after 2020 have this by default)
- USB 3.0 SATA SSD
- The Pi's SSH host key age public key (obtained after first boot)

> **Check USB boot support**: If unsure, boot Raspberry Pi OS from SD card and run:
> `vcgencmd bootloader_config | grep BOOT_ORDER`
> If it includes `0x4` (USB), you're good. Otherwise run `sudo raspi-config` → Advanced → Boot Order → USB Boot.

## Step 1: Build and flash NixOS image

```bash
nix build .#nixosConfigurations.homerpilab.config.system.build.sdImage
sudo dd if=result/sd-image/nixos-sd-image-*.img of=/dev/sdX bs=4M status=progress conv=fsync && sync
```

## Step 2: First boot

1. Connect SSD to Pi and power on
2. Find the Pi via mDNS: `ping homerpilab.local` (Avahi is enabled)
3. SSH in: `ssh piotr@homerpilab.local`

## Step 3: Set up secrets

On your workstation, get the host's age public key:

```bash
ssh-keyscan homerpilab.local 2>/dev/null | nix-shell -p ssh-to-age --run ssh-to-age
```

Then in `nix-config-private`:

1. Replace `PLACEHOLDER_REPLACE_WITH_AGE_KEY_AFTER_FIRST_BOOT` in `.sops.yaml` with the real key
2. Create the encrypted secrets file:
   ```bash
   sops secrets/homerpilab.yaml
   ```
   Add: `piotr-password-hash`, `tailscale-auth-key`, `builder-key`

3. Commit and push nix-config-private

## Step 4: Deploy

```bash
# Push nix-config, then rebuild on the Pi
ssh piotr@homerpilab.local "cd ~/nix-config && git pull && sudo nixos-rebuild switch --flake .#homerpilab"
```

## Step 5: Verify

```bash
ssh piotr@homerpilab.local
ls -la /run/secrets/           # Secrets decrypted
systemctl status tailscaled    # Tailscale running
systemctl status sshd          # SSH running
```

## Optional: Static IP

When you have a LAN IP assigned, add to `default.nix`:

```nix
networking.interfaces.end0.ipv4.addresses = [{
  address = "192.168.68.XXX";
  prefixLength = 24;
}];
networking.defaultGateway = "192.168.68.1";
networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
```
