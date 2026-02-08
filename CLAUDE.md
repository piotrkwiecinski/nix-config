# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Multi-host NixOS configuration using flake-parts for modular management. Manages three hosts:
- **homelab**: Desktop workstation (x86_64-linux)
- **thinkpad-x1-g3**: Laptop with NVIDIA/Intel GPU, YubiKey (x86_64-linux)
- **homeserver**: Raspberry Pi 4 running Nextcloud, Home Assistant, Blocky DNS (aarch64-linux)

## Commands

Commands like `nix-switch`, `home-switch`, and `treefmt` are provided by the dev shell. If a command is not found, run it via `nix develop`:

```bash
nix develop --command bash -c 'nix-switch'    # Run a dev shell command directly
nix develop                                    # Or enter the shell interactively
nix-switch               # Rebuild NixOS: sudo nixos-rebuild switch --flake ".#$(hostname)"
home-switch              # Rebuild home-manager: home-manager switch -b backup --flake ".#$(whoami)@$(hostname)"
treefmt                  # Format all Nix files with nixfmt
```

Remote deployment to homeserver:
```bash
nixos-rebuild switch --flake ".#homeserver" --target-host piotr@homeserver --sudo
```

**Important**: New files must be staged with `git add` before running nix builds. Flakes only see files tracked by git.

## Architecture

### Flake-parts Module System

The configuration uses flake-parts for composability. Main entry point is `flake.nix`, which imports:

- `parts/nixos.nix` - Creates nixosConfigurations using `mkHost` helper
- `parts/home-manager.nix` - Creates homeConfigurations using `mkHome` helper
- `parts/dev-shell.nix` - Development shell with `nix-switch` and `home-switch` commands
- `parts/overlays.nix` - Dynamic overlay loading from `overlays/modifications/`
- `parts/packages.nix` - Custom packages from `pkgs/`
- `parts/formatter.nix` - Treefmt configuration

### Directory Layout

```
hosts/                     # Per-host NixOS configurations
  {hostname}/
    default.nix            # Host-specific system config
    hardware-configuration.nix  # Auto-generated hardware config

home/piotr/                # Home-manager configurations
  global/                  # Shared across all hosts (git, nix settings)
  features/                # Optional modules (emacs, direnv, firefox)
  {hostname}.nix           # Host-specific user config

users/piotr/               # User account NixOS module

parts/                     # Flake-parts modules

overlays/modifications/    # Package overlays (auto-loaded)

pkgs/                      # Custom package definitions
```

### Key Patterns

**Host-specific module loading**: User configs are dynamically imported based on hostname:
```nix
home-manager.users.piotr = import ../../home/piotr/${config.networking.hostName}.nix;
```

**Multi-version nixpkgs**: Access to three channels via overlays:
- `pkgs` - nixos-25.11 stable
- `pkgs.unstable` - nixos-unstable
- `pkgs.master` - master branch

**Conditional configuration**: Features check for sops template availability before enabling:
```nix
lib.optionals (hasSopsTemplate "git-personal-github.inc") [ ... ]
```

### Private Repository

Sensitive configuration lives in `nix-config-private` (SSH flake input). It provides:
- sops-nix modules for secrets management
- Host-specific secrets (passwords, keys)
- Work-related SSH/Git configs

Secrets are encrypted with age. Key types by host:
- homeserver: SSH host key (`/etc/ssh/ssh_host_ed25519_key`)
- thinkpad-x1-g3: Standalone age key (`/var/lib/sops-nix/key.txt`)

### Distributed Builds

The homeserver (aarch64) delegates builds to thinkpad-x1-g3 (x86_64) using:
- QEMU emulation support on thinkpad
- `builder` user accepting SSH connections
- Builder SSH key managed via sops-nix at `/etc/nix/builder_key`

## Code Style

- Format: nixfmt (run `treefmt`)
- Indentation: 2 spaces
- Excluded from formatting: `hardware-configuration.nix` files (auto-generated)
