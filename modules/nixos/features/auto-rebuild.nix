# Nightly self-rebuild of a host from its own nix-config clone: pull main,
# build, and switch only when the system actually changed. The clone and the
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
        config.systemd.package
      ];
      environment.HOME = "/root";
      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "nix-config-auto-rebuild";
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
        runuser -u ${lib.escapeShellArg cfg.user} -- git -C "$flake" pull --ff-only --quiet
        rev=$(runuser -u ${lib.escapeShellArg cfg.user} -- git -C "$flake" rev-parse HEAD)

        if [ "$(cat ${stateFile} 2>/dev/null || true)" = "$rev" ]; then
          echo "Already built $rev; nothing to do."
          exit 0
        fi

        system=$(nix build --no-link --print-out-paths \
          "$flake#nixosConfigurations.${config.networking.hostName}.config.system.build.toplevel")

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
