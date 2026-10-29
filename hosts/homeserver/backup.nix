# Encrypted restic backups of Home Assistant, Paperless and food-planner, and the
# `homeserver-restore` tool (docs/backup-restore.org). The repository and
# password files are options so that checks/backup-restore.nix can run this
# exact module in a VM against a local rest-server.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homeserver.backup;
  repo = {
    inherit (cfg) repositoryFile passwordFile;
    initialize = true;
  };
in
{
  options.homeserver.backup = {
    repositoryFile = lib.mkOption {
      type = lib.types.str;
      description = "File holding the restic repository URL (with rest-server credentials).";
    };
    passwordFile = lib.mkOption {
      type = lib.types.str;
      description = "File holding the restic repository password.";
    };
  };

  config = {
    # The repository is append-only: this host can add snapshots but not
    # delete them; retention and checks run where the repository lives.
    services.restic.backups = {
      # Stop HA for a consistent SQLite snapshot; the cleanup command runs
      # even when the backup fails.
      hass = repo // {
        paths = [ "/var/lib/hass" ];
        exclude = [
          "/var/lib/hass/home-assistant.log*"
          "/var/lib/hass/OZW_Log.txt*"
          "/var/lib/hass/tmp"
          "/var/lib/hass/deps"
          "/var/lib/hass/.cache"
        ];
        backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop home-assistant.service";
        backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start home-assistant.service";
        timerConfig = {
          OnCalendar = "*-*-* 12:00:00";
          Persistent = true;
        };
      };

      # food-planner's scheduled meals: a consistent copy through SQLite's
      # online backup, so the app keeps running.
      food-planner = repo // {
        paths = [ "/var/lib/food-planner/backup" ];
        backupPrepareCommand = ''
          ${pkgs.coreutils}/bin/mkdir -p /var/lib/food-planner/backup
          ${pkgs.sqlite}/bin/sqlite3 /var/lib/food-planner/food-planner.db \
            ".backup /var/lib/food-planner/backup/food-planner.db"
        '';
        timerConfig = {
          OnCalendar = "*-*-* 12:30:00";
          Persistent = true;
        };
      };

      # Started by the nightly paperless-exporter run, not by its own timer
      paperless = repo // {
        paths = [ "/var/lib/paperless/export" ];
        timerConfig = null;
      };
    };
    systemd.services.paperless-exporter.onSuccess = [ "restic-backups-paperless.service" ];

    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "homeserver-restore";
        runtimeInputs = [
          pkgs.restic
          pkgs.jq
          pkgs.sqlite
          pkgs.coreutils
          pkgs.findutils
          pkgs.util-linux
          pkgs.systemd
          config.services.postgresql.package
          config.services.paperless.manage
        ];
        runtimeEnv = {
          RESTIC_REPOSITORY_FILE = cfg.repositoryFile;
          RESTIC_PASSWORD_FILE = cfg.passwordFile;
        };
        text = builtins.readFile ./restore.sh;
      })
    ];
  };
}
