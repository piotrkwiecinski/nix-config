# Optimize boot speed

## Problem

The system likely spends 15-25 unnecessary seconds booting due to: 5s boot menu timeout, NVIDIA modules in initrd (not needed for PRIME offload), NetworkManager-wait-online blocking, and verbose boot output.

## Diagnostic (run before and after changes)

```bash
systemd-analyze                    # Overall boot time
systemd-analyze blame              # Services sorted by start time
systemd-analyze critical-chain     # What blocks the desktop
```

## Changes

### `hosts/thinkpad-x1-g3/default.nix`

```nix
# Skip boot menu (hold Space to access it when needed) -- saves ~5s
boot.loader.timeout = 0;

# Move NVIDIA out of initrd -- saves ~3-5s initrd decompression.
# Intel iGPU drives the display in PRIME offload mode, so NVIDIA
# modules are not needed for early KMS.
boot.initrd.kernelModules = lib.mkForce [ ];

# NVIDIA modules load during normal boot instead (before GDM starts)
# Note: kvm-intel is already in hardware-configuration.nix and will merge.
boot.kernelModules = [
  "nvidia"
  "nvidia_modeset"
  "nvidia_uvm"
  "nvidia_drm"
];

# Don't wait for network before reaching desktop -- saves ~2-5s
systemd.services.NetworkManager-wait-online.enable = false;

# Disable CUPS printer auto-discovery (add printers manually) -- saves ~1-2s
services.printing.browsed.enable = false;

# Silent boot -- cleaner visual transition
boot.consoleLogLevel = 0;
boot.kernelParams = [
  # ... existing params ...
  "quiet"
  "loglevel=3"
  "systemd.show_status=auto"
  "rd.udev.log_level=3"
];
```

## Rationale

### Boot menu timeout

`boot.loader.timeout = 0` eliminates the 5-second systemd-boot menu wait. The menu is still accessible by holding Space during boot.

### NVIDIA out of initrd

With PRIME offload (`offload.enable = true`), the Intel iGPU is the primary display. The i915 driver handles early display output. Loading NVIDIA in initrd adds ~50MB+ to the initrd image that must be decompressed, but provides no benefit since Intel handles display. NVIDIA modules are still loaded before GDM starts via `boot.kernelModules`.

### NetworkManager-wait-online

This service blocks boot until the network is fully configured. On a desktop/laptop, you don't need network connectivity before reaching the login screen. This is the most commonly cited NixOS boot optimization.

### cups-browsed

`cups-browsed` auto-discovers network printers via mDNS. If printers are configured manually, this adds 1-2 seconds for no benefit.

### Silent boot

Suppresses kernel/systemd messages for a cleaner visual transition from bootloader to GDM. No actual speed gain, but improves perceived boot experience.

## What NOT to do

- **Plymouth**: Crashes with GDM + autologin ([NixOS/nixpkgs#309190](https://github.com/NixOS/nixpkgs/issues/309190)).
- **`boot.initrd.systemd.enable`**: No measurable speed gain; risky with autologin + GDM.

## Expected savings

| Optimization | Estimated savings |
|---|---|
| `boot.loader.timeout = 0` | ~5 seconds |
| NVIDIA out of initrd | ~3-5 seconds |
| NetworkManager-wait-online | ~2-5 seconds |
| cups-browsed | ~1-2 seconds |
| **Total** | **~11-17 seconds** |
