# `homeserver-restore`: list, verify and restore the restic backups of Home
# Assistant and Paperless. Procedure: docs/backup-restore.org.
{ config, pkgs, ... }:
{
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
        RESTIC_REPOSITORY_FILE = config.sops.secrets."restic-repository".path;
        RESTIC_PASSWORD_FILE = config.sops.secrets."restic-password".path;
      };
      text = builtins.readFile ./restore.sh;
    })
  ];
}
