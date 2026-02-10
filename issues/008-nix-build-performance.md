# Optimize Nix build parallelism, downloads, and daemon scheduling

## Problem

The default Nix settings are conservative: `max-jobs = 1` builds one derivation at a time, the daemon uses default CPU/IO priority (competing with interactive tasks), and download parallelism is modest for a setup with 4 binary caches.

## Changes

### `hosts/thinkpad-x1-g3/default.nix` -- replace the existing `nix` block

```nix
nix = {
  settings = {
    auto-optimise-store = true;

    # -- Parallel builds (8 cores / 16 threads) --
    max-jobs = 4;    # Build 4 derivations simultaneously (default: 1)
    cores = 4;       # Each build gets 4 threads (4 x 4 = 16 total)

    # -- Download parallelism --
    max-substitution-jobs = 32;        # Default: 16. More parallel cache downloads
    http-connections = 50;             # Default: 25. More TCP connections
    connect-timeout = 5;              # Default: 0. Fail fast on unreachable caches
    stalled-download-timeout = 15;    # Default: 300. Don't hang on stalled downloads
    download-attempts = 3;            # Default: 5. Fewer retries for faster failover
    narinfo-cache-negative-ttl = 300; # Default: 3600. Re-check caches sooner after miss

    # -- Binary caches with explicit priority --
    extra-substituters = [
      "https://nix-community.cachix.org?priority=41"
      "https://emacs-ci.cachix.org?priority=42"
      "https://devenv.cachix.org?priority=43"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "emacs-ci.cachix.org-1:B5FVOrxhXXrOL0S+tQ7USrhjMT5iOPH+QN9q0NItom4="
    ];

    # -- Registry and evaluation --
    flake-registry = "";  # Disable global registry fetch (saves network roundtrip)

    # -- Existing settings --
    keep-outputs = true;
    keep-derivations = true;
    experimental-features = "nix-command flakes";
    trusted-users = [ "root" "piotr" "builder" ];
  };

  # -- Daemon scheduling: deprioritize builds for desktop responsiveness --
  daemonCPUSchedPolicy = "batch";      # Non-interactive CPU scheduling
  daemonIOSchedClass = "best-effort";  # Don't completely starve builds
  daemonIOSchedPriority = 4;           # Medium-low I/O priority (range: 0-7)

  # -- Disable channels (unused with flakes) --
  channel.enable = false;
  nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  registry.nixpkgs.flake = inputs.nixpkgs;
};
```

## Rationale

### Build parallelism

| Setting | Before | After | Effect |
|---|---|---|---|
| `max-jobs` | 1 | 4 | 4 derivations build simultaneously |
| `cores` | 0 (all 16) | 4 | Each build gets 4 threads |

The split `max-jobs = 4, cores = 4` balances parallelism (4 x 4 = 16 threads max) without oversubscribing RAM. Most nixpkgs derivations use `enableParallelBuilding` and will utilize `NIX_BUILD_CORES`.

### Daemon scheduling

`batch` CPU policy tells the kernel the process is non-interactive and applies a mild scheduling penalty. Combined with `daemonIOSchedPriority = 4`, builds yield to interactive tasks (browser, editor, file manager) without being completely starved. This is less aggressive than `idle` (which can make `nixos-rebuild` unreasonably slow).

### Download settings

With 4 binary caches, increasing `max-substitution-jobs` to 32 and `http-connections` to 50 allows better parallelism. The `connect-timeout = 5` and `stalled-download-timeout = 15` prevent hanging when a cache is temporarily unreachable.

### `flake-registry = ""`

Prevents Nix from fetching `https://channels.nixos.org/flake-registry.json` on first use. Since `nix.registry.nixpkgs.flake` is already pinned, the global registry is unnecessary.

### `channel.enable = false`

Channels are unused with a pure-flake workflow. This removes the channel management overhead.
