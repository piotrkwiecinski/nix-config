# CLAUDE.md

Remote deployment to homeserver:
```bash
nixos-rebuild switch --flake ".#homeserver" --target-host piotr@homeserver --sudo
```

**Important**: New files must be staged with `git add` before running nix builds. Flakes only see files tracked by git.

Sensitive configuration lives in `nix-config-private` (SSH flake input). It provides:
- sops-nix modules for secrets management
- Host-specific secrets (passwords, keys)
- Work-related SSH/Git configs

Secrets are encrypted with age. Key types by host:
- homeserver: SSH host key (`/etc/ssh/ssh_host_ed25519_key`)
- thinkpad-x1-g3: Standalone age key (`/var/lib/sops-nix/key.txt`)
