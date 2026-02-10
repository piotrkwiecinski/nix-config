# Fix NVIDIA power management: allow GPU D3 sleep and remove conflicting env vars

## Problem

Two issues waste power and cause incorrect GPU behavior:

1. **`nvidiaPersistenced = true` prevents GPU D3 sleep.** nvidia-persistenced keeps the driver permanently loaded, which blocks the GPU from entering D3cold state. With fine-grained power management enabled, the GPU should power off completely when idle, saving 3-5W. Currently the GPU draws ~3.2W at idle with 0% utilization.

2. **Global `GBM_BACKEND=nvidia-drm` and `__GLX_VENDOR_LIBRARY_NAME=nvidia` break PRIME offload.** These variables force all GBM allocations and GLX through NVIDIA, but on a PRIME offload setup the Intel iGPU should be the primary renderer. These vars are intended for per-application use via the `nvidia-offload` command (already available from `enableOffloadCmd`).

## Changes

### `hosts/thinkpad-x1-g3/default.nix`

```nix
hardware.nvidia = {
  open = false;
  nvidiaPersistenced = false;  # Changed: allow GPU to enter D3 sleep

  powerManagement = {
    enable = true;
    finegrained = true;
  };

  prime = {
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
    offload = {
      enable = true;
      enableOffloadCmd = true;
    };
  };
};

# Remove GBM_BACKEND and __GLX_VENDOR_LIBRARY_NAME -- they conflict with PRIME offload.
# Use `nvidia-offload <command>` for per-application GPU offload instead.
environment.sessionVariables = {
  NVD_BACKEND = "direct";  # Keep: needed for nvidia-vaapi-driver
};
```

## Verification

After applying, verify GPU power state:

```bash
cat /sys/bus/pci/devices/0000:01:00.0/power/control    # Should be "auto"
cat /proc/driver/nvidia/gpus/*/power                     # Should show "Runtime D3 status: Enabled"
cat /sys/bus/pci/devices/0000:01:00.0/power_state       # Should be "D3cold" when idle
```

## Rationale

### nvidiaPersistenced

The trade-off is slightly slower GPU wake-up (~100-200ms) when first running an offloaded application. The battery savings of 3-5W at idle are substantial -- potentially 30-60 minutes of additional battery life.

### Global NVIDIA environment variables

Setting `GBM_BACKEND=nvidia-drm` globally forces GNOME Shell/Mutter to route compositing through the NVIDIA driver instead of Intel, causing inefficient GPU-to-GPU copies. On PRIME offload, the compositor should use Intel, and only explicitly offloaded applications should use NVIDIA. The `nvidia-offload` wrapper (from `enableOffloadCmd`) sets these variables per-application.

`NVD_BACKEND=direct` is unrelated -- it tells the nvidia-vaapi-driver to use direct rendering for hardware video decode, and should be kept.
