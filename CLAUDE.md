# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Multi-host NixOS configuration using flake-parts for modular management. Manages three hosts plus a LiveCD ISO:
- **homelab**: Desktop workstation (x86_64-linux)
- **thinkpad-x1-g3**: Laptop with NVIDIA/Intel GPU, YubiKey, COSMIC desktop (x86_64-linux)
- **homeserver**: Raspberry Pi 4 running Nextcloud, Home Assistant, Blocky DNS (aarch64-linux)
- **iso**: LiveCD for host setup and configuration restore (x86_64-linux)

## Commands

Commands like `nix-switch`, `home-switch`, and `treefmt` are provided by the dev shell. If a command is not found, run it via `nix develop`:

```bash
nix develop --command bash -c 'nix-switch'    # Run a dev shell command directly
nix develop                                    # Or enter the shell interactively
nix-switch               # Rebuild NixOS: sudo nixos-rebuild switch --flake ".#$(hostname)"
home-switch              # Rebuild home-manager: home-manager switch -b backup --flake ".#$(whoami)@$(hostname)"
nix fmt                  # Format all Nix files with nixfmt
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
- `parts/iso.nix` - Creates the `iso` nixosConfiguration (LiveCD, uses nixpkgs directly, not `mkHost`)
- `parts/home-manager.nix` - Creates homeConfigurations using `mkHome` helper
- `parts/dev-shell.nix` - Development shell with `nix-switch` and `home-switch` commands
- `parts/overlays.nix` - Dynamic overlay loading from `overlays/modifications/`
- `parts/packages.nix` - Custom packages from `pkgs/`
- `parts/formatter.nix` - Treefmt configuration

**Helper signatures:**
```nix
mkHost { hostname = "name"; system ? "x86_64-linux"; }  # imports hosts/{hostname}/
mkHome { username = "name"; hostname = "name"; system ? "x86_64-linux"; }  # imports home/{username}/{hostname}.nix
```

Both helpers pass `inputs` and `outputs` via `specialArgs`/`extraSpecialArgs`.

### Directory Layout

```
hosts/                     # Per-host NixOS configurations
  {hostname}/
    default.nix            # Host-specific system config
    disk-config.nix        # Disko declarative disk layout (optional)
    hardware-configuration.nix  # Auto-generated hardware config
  iso/
    default.nix            # LiveCD configuration (GNOME installer base)

home/piotr/                # Home-manager configurations
  global/                  # Shared across all hosts (git, nix settings)
  features/                # Optional modules (emacs, direnv, firefox)
  {hostname}.nix           # Host-specific user config

users/piotr/               # User account NixOS module

parts/                     # Flake-parts modules

overlays/modifications/    # Package overlays (auto-loaded)

pkgs/                      # Custom package definitions
```

### Disko (Declarative Disk Management)

Disk layouts are declared with [disko](https://github.com/nix-community/disko). Currently used on thinkpad-x1-g3 in **adoption mode** (manages mount configuration only — never run `disko format` on an existing disk).

- Flake input: `inputs.disko`
- NixOS module: `inputs.disko.nixosModules.disko` (imported in host `default.nix`)
- Disk config: `hosts/{hostname}/disk-config.nix`
- Disko replaces `fileSystems.*` and `swapDevices` in `hardware-configuration.nix`; those entries should be removed when adopting disko

### LiveCD ISO

The `iso` nixosConfiguration produces a bootable GNOME-based installer ISO named `nixos-setup`. It is built via `parts/iso.nix` which uses `inputs.nixpkgs.lib.nixosSystem` directly (not `mkHost`) and imports the NixOS graphical GNOME installer base module.

Build the ISO:
```bash
nix build .#nixosConfigurations.iso.config.system.build.isoImage
```

The ISO includes:
- **Editor & AI**: Emacs 30 (pgtk, from unstable), `claude-code-bin` (from master), git
- **Nix tooling**: `nil`, `nix-output-monitor`, `nixfmt-rfc-style`
- **Disk & filesystem**: `disko`, `btrfs-progs`, `parted`, `gptfdisk`, `dosfstools`
- **Secrets & security**: `sops`, `age`, `ssh-to-age`
- **General utilities**: `ripgrep`, `htop`, `jq`, `rsync`, `pciutils`, `usbutils`

The ISO uses the repo's overlay (`outputs.overlays.default`) so custom packages are available.

### Adding a New Host

1. Create `hosts/{hostname}/default.nix` (imports home-manager, hardware, user module, private-nix-config modules)
2. Create `hosts/{hostname}/hardware-configuration.nix`
3. Create `home/piotr/{hostname}.nix` (imports `./global` and desired features)
4. Add `mkHost` call in `parts/nixos.nix`
5. Add `mkHome` call in `parts/home-manager.nix`
6. `git add` all new files before building

### Adding Overlays and Packages

**Overlay**: Create `overlays/modifications/{name}.nix` with signature:
```nix
{ inputs }: final: prev: { /* modifications */ }
```
Files are auto-discovered; no registration needed.

**Custom package**: Add to `pkgs/default.nix`. Each package receives `pkgs` and `pkgs-unstable`. Packages are auto-loaded into the overlay.

Current custom packages:
- `dm` — Docker Compose helper: walks up directories to find `compose.yaml`, then dispatches to `./bin/<command>`
- `claude-code-ide` — Emacs package built from GitHub (`manzaltu/claude-code-ide.el`) with upstream patches applied
- `magento-cache-clean` — Magento 2 cache watcher (Node.js wrapper)

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

### Project Tracking

Planned changes are tracked in `issues/` as markdown files (`{number}-{slug}.md`). Completed issues are deleted.

## Code Style

- Format: nixfmt (run `nix fmt`)
- Indentation: 2 spaces
- Excluded from formatting: `hardware-configuration.nix` files (auto-generated)
