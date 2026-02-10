# Replace power-profiles-daemon with TLP for comprehensive power management

## Problem

GNOME enables `power-profiles-daemon` by default, which only manages 4 settings (platform profile, CPU energy performance policy, CPU boost, AMDGPU ABM level). It provides **no** idle power savings for WiFi, USB autosuspend, disk spin-down, PCI runtime PM, or SATA link power management.

The nixos-hardware module tries to enable TLP (`services.tlp.enable = mkDefault true`) but it evaluates to `false` because power-profiles-daemon is already active.

## Changes

### `hosts/thinkpad-x1-g3/default.nix`

```nix
# Disable GNOME's limited power-profiles-daemon
services.power-profiles-daemon.enable = false;

# TLP with GNOME-compatible D-Bus interface (tlp-pd)
services.tlp = {
  enable = true;
  pd.enable = true;  # Implements power-profiles-daemon D-Bus API for GNOME Settings

  settings = {
    # CPU: performance on AC, powersave on battery
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

    # Intel HWP energy performance hints
    CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

    # CPU frequency limits (intel_pstate driver)
    CPU_MIN_PERF_ON_AC = 0;
    CPU_MAX_PERF_ON_AC = 100;
    CPU_MIN_PERF_ON_BAT = 0;
    CPU_MAX_PERF_ON_BAT = 30;

    # Disable turbo boost on battery for thermals + battery
    CPU_BOOST_ON_AC = 1;
    CPU_BOOST_ON_BAT = 0;

    # WiFi power saving
    WIFI_PWR_ON_AC = "off";
    WIFI_PWR_ON_BAT = "on";

    # PCI Express Active State Power Management
    PCIE_ASPM_ON_AC = "default";
    PCIE_ASPM_ON_BAT = "powersupersave";

    # Runtime PM for PCI(e) devices
    RUNTIME_PM_ON_AC = "on";
    RUNTIME_PM_ON_BAT = "auto";

    # ThinkPad battery charge thresholds (preserves battery longevity)
    START_CHARGE_THRESH_BAT0 = 20;
    STOP_CHARGE_THRESH_BAT0 = 80;

    # SATA link power management
    SATA_LINKPWR_ON_AC = "med_power_with_dipm";
    SATA_LINKPWR_ON_BAT = "med_power_with_dipm";

    # USB autosuspend
    USB_AUTOSUSPEND = 1;
  };
};

# Intel thermal management -- helps with DPTF adaptive thermal tables
services.thermald.enable = true;

# Install powertop for diagnostics only (do NOT enable auto-tune -- conflicts with TLP)
# Add to environment.systemPackages: pkgs.powertop
```

## Rationale

### TLP with pd.enable

Starting with TLP 1.9, the `tlp-pd` daemon implements the same D-Bus API that GNOME uses for power profile selection. This means GNOME Settings > Power > Power Mode works transparently, while TLP manages the full set of power-saving tunables that power-profiles-daemon ignores.

### Battery charge thresholds

`START_CHARGE_THRESH_BAT0 = 20` / `STOP_CHARGE_THRESH_BAT0 = 80` keeps the battery between 20-80%, which significantly extends battery longevity on ThinkPads (supported via the `thinkpad_acpi` kernel module).

### thermald

Intel's thermal daemon with `--adaptive` (NixOS default) reads DPTF tables from the firmware. On 10th gen Intel ThinkPads, this helps the CPU sustain higher clocks by proactively managing thermals before firmware imposes hard limits.

### What NOT to enable alongside TLP

- **auto-cpufreq**: Conflicts with TLP on CPU frequency management.
- **powertop auto-tune**: Manages the same tunables as TLP, causing overwrites.
- **Undervolting**: BIOS-locked on ThinkPad X1 Extreme Gen 3 (Plundervolt/CVE-2019-11157 mitigation).
