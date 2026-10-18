# CLAUDE.md

Deploying the Pis (homeserver, homerpilab), from the dev shell. Push first; the Pi pulls its `~/nix-config` clone and rebuilds itself in a transient `nixos-rebuild-manual` unit:
```bash
nix develop -c pi-switch homeserver
```
Fallback for a Pi without its clone or token yet (evaluates here, builds and activates on the Pi):
```bash
nix develop -c pi-deploy homerpilab
```

Private flake inputs are fetched from GitHub with the token in the `nix-access-tokens` sops secret, which `modules/nixos/base.nix` includes into nix.conf, so root can fetch them too. A host without it needs the token in `NIX_CONFIG` for its first build.

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
