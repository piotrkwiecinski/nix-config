# CLAUDE.md

Remote deployment to homeserver:
```bash
nixos-rebuild switch --flake ".#homeserver" --build-host piotr@homeserver --target-host piotr@homeserver --sudo
```

**Important**: New files must be staged with `git add` before running nix builds. Flakes only see files tracked by git.

Sensitive configuration lives in `nix-config-private` (SSH flake input). It provides:
- sops-nix modules for secrets management
- Host-specific secrets (passwords, keys)
- Work-related SSH/Git configs

Secrets are encrypted with age. Key types by host:
- homeserver: SSH host key (`/etc/ssh/ssh_host_ed25519_key`)
- thinkpad-x1-g3: Standalone age key (`/var/lib/sops-nix/key.txt`)

## Commits touching the private flake input

This repo is public. When a commit bumps `private-nix-config` in `flake.lock`, the message must be exactly:

```
chore(flake): bump private-nix-config
```

No suffix, no body — never describe what changed in the private repo (module names, secrets, features). Enforced by `.githooks/commit-msg`, which the dev shell enables via `core.hooksPath`. For commits that also change public code, mention the bump only as `Bump private-nix-config` and keep private details out of the subject and body.
