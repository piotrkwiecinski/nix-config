# Nightly self-rebuild of a host from its own nix-config clone: fetch main,
# check that a trusted key signed it, build, and switch only when the system
# actually changed. The clone and the
# root-side evaluation are the same ones `pi-switch` uses, so a manual deploy
# and this unit stay interchangeable.
#
# It skips (exit 0, warning priority so `journalctl -p warning` shows it) while
# a manual `pi-switch` (nixos-rebuild-manual), any other nixos-rebuild, or one
# of `skipWhileActive` is running, and checks again just before activating.
# `pi-switch` in turn refuses to start while this unit is active.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.nix-config-auto-rebuild;
  stateFile = "/var/lib/nix-config-auto-rebuild/evaluated-rev";
in
{
  options.services.nix-config-auto-rebuild = {
    enable = lib.mkEnableOption "nightly rebuild from the local nix-config clone";

    flakeDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/piotr/nix-config";
      description = "Clone to pull and build from.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "piotr";
      description = "Owner of the clone; git runs as this user.";
    };

    startAt = lib.mkOption {
      type = lib.types.str;
      description = "systemd OnCalendar expression for the run.";
    };

    skipWhileActive = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "restic-backups-*.service" ];
      description = "Unit patterns that make the run skip while any is running.";
    };

    signingKeys = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      # builtins.path copies just the key, not the whole flake source
      default = [
        (builtins.path {
          path = ../../../keys/commit-signing.asc;
          name = "commit-signing.asc";
        })
      ];
      defaultText = lib.literalExpression "[ ./keys/commit-signing.asc ]";
      description = ''
        Armored OpenPGP public keys. The fetched commit is built only if one of
        them signed it; the unit fails otherwise. An empty list builds unsigned
        commits too.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.nix-config-auto-rebuild = {
      description = "Rebuild ${config.networking.hostName} from ${cfg.flakeDir} when main moved";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      startAt = cfg.startAt;
      # The run activates the generation that may redefine this unit; a
      # restart would kill switch-to-configuration halfway through.
      restartIfChanged = false;
      path = [
        config.nix.package
        pkgs.git
        pkgs.util-linux
        pkgs.procps
        pkgs.coreutils
        pkgs.gnupg
        config.systemd.package
      ];
      environment.HOME = "/root";
      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "nix-config-auto-rebuild";
        RuntimeDirectory = "nix-config-auto-rebuild";
        TimeoutStartSec = "3h";
      };
      script = ''
        set -euo pipefail

        busy() {
          if systemctl is-active --quiet nixos-rebuild-manual.service; then
            echo "<4>A manual pi-switch is running; skipping."
            return 0
          fi
          if pgrep -f 'nixos-rebuild[^ ]* +(switch|build|boot|test|dry-activate|dry-build)' >/dev/null; then
            echo "<4>A nixos-rebuild is already running; skipping."
            return 0
          fi
          ${lib.optionalString (cfg.skipWhileActive != [ ]) ''
            units=$(systemctl list-units --no-legend --plain \
              --state=activating,active,reloading,deactivating \
              ${lib.escapeShellArgs cfg.skipWhileActive} | cut -d' ' -f1)
            if [ -n "$units" ]; then
              echo "<4>Skipping while running: $units"
              return 0
            fi
          ''}
          return 1
        }

        if busy; then exit 0; fi

        flake=${lib.escapeShellArg cfg.flakeDir}
        asUser() { runuser -u ${lib.escapeShellArg cfg.user} -- "$@"; }
        asUser git -C "$flake" fetch --quiet
        rev=$(asUser git -C "$flake" rev-parse '@{upstream}')
        ${lib.optionalString (cfg.signingKeys != [ ]) ''
          # Root checks the signature against keys from the store, in a keyring
          # of its own, so neither the clone's owner nor GitHub can vouch for a
          # commit.
          export GNUPGHOME="$RUNTIME_DIRECTORY/gnupg"
          rm -rf "$GNUPGHOME"
          mkdir -m 700 "$GNUPGHOME"
          trap 'gpgconf --kill all; rm -rf "$GNUPGHOME"' EXIT
          gpg --batch --quiet --import ${lib.escapeShellArgs cfg.signingKeys}
          if ! git -c safe.directory="$flake" -C "$flake" verify-commit "$rev" 2>/dev/null; then
            echo "<3>$rev is not signed by a trusted key; not building it."
            exit 1
          fi
        ''}
        asUser git -C "$flake" merge --ff-only --quiet "$rev"

        if [ "$(cat ${stateFile} 2>/dev/null || true)" = "$rev" ]; then
          echo "Already built $rev; nothing to do."
          exit 0
        fi

        # Build the verified commit itself, not whatever the work tree holds.
        system=$(nix build --no-link --print-out-paths \
          "git+file://$flake?rev=$rev#nixosConfigurations.${config.networking.hostName}.config.system.build.toplevel")

        if [ "$system" = "$(readlink -f /run/current-system)" ]; then
          echo "$rev builds the running system; nothing to switch."
          echo "$rev" > ${stateFile}
          exit 0
        fi

        # The build can take a while; something may have started meanwhile.
        if busy; then exit 0; fi

        echo "Switching to $system ($rev)"
        nix-env -p /nix/var/nix/profiles/system --set "$system"
        "$system/bin/switch-to-configuration" switch
        echo "$rev" > ${stateFile}
      '';
    };
  };
}
