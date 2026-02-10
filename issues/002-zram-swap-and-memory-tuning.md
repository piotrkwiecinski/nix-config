# Enable zram swap and tune memory management sysctls

## Problem

The system has `swapDevices = []` -- no swap at all. When RAM is exhausted, the OOM killer activates immediately with no graceful degradation. This is especially problematic during large Nix builds. Additionally, kernel dirty-page writeback defaults are tuned for HDDs, not NVMe SSDs.

## Changes

### `hosts/thinkpad-x1-g3/default.nix`

```nix
# Compressed RAM swap -- prevents OOM kills, extends effective RAM
zramSwap = {
  enable = true;
  algorithm = "zstd";
  memoryPercent = 50;
};

# Kernel memory management tuning
boot.kernel.sysctl = {
  # -- zram-optimized swap behavior --
  # With zram, higher swappiness is correct: decompressing from RAM is
  # orders of magnitude faster than NVMe I/O. Values >100 are valid
  # for in-memory swap backends (kernel docs).
  "vm.swappiness" = 180;
  "vm.watermark_boost_factor" = 0;    # Disable; no real disk I/O to optimize for
  "vm.watermark_scale_factor" = 125;  # Start kswapd earlier to smooth pressure
  "vm.page-cluster" = 0;             # No prefetch needed for RAM-backed swap

  # -- Desktop responsiveness --
  "vm.vfs_cache_pressure" = 50;       # Prefer keeping VFS caches (faster file access)

  # -- SSD-optimized dirty page writeback --
  "vm.dirty_background_ratio" = 5;    # Start background flush sooner (default: 10)
  "vm.dirty_ratio" = 10;              # Force-flush threshold (default: 20), prevents stalls
};

# Distribute hardware interrupts across CPU cores
services.irqbalance.enable = true;
```

## Rationale

### zram

- With `zstd` compression and typical 2-3x ratio, `memoryPercent = 50` uses ~17-25% of actual RAM while presenting ~50% as swap capacity.
- Decompressing zram pages is ~1000x faster than NVMe reads; the kernel should prefer swapping to zram over evicting file caches.
- `vm.swappiness = 180` is based on Fedora/Arch/Pop!_OS defaults for zram and the [proposed NixOS PR #351002](https://github.com/NixOS/nixpkgs/pull/351002) (still unmerged, so manual config required).
- `vm.page-cluster = 0` disables swap prefetch -- no benefit when swap is in RAM.

### Dirty page tuning

- Default `dirty_ratio = 20` allows 20% of RAM as dirty pages before blocking writes. On a system with 32GB RAM, that's 6.4GB of pending writes -- leading to multi-second I/O stalls when flushed.
- Lowering to `dirty_ratio = 10` and `dirty_background_ratio = 5` keeps write stalls short and smooth.

### irqbalance

- Lightweight daemon (wakes every 10 seconds) that distributes hardware interrupts across CPU cores.
- Without it, CPU 0 handles most interrupts, which can bottleneck under heavy NVMe + WiFi + USB activity (e.g., during large Nix builds with network downloads).
