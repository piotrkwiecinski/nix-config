{
  config,
  inputs,
  outputs,
  ...
}:
{
  imports = [
    outputs.nixosModules.rpi4
    outputs.nixosModules.samba
    outputs.nixosModules.home-cache
    ./hardware-configuration.nix
    # sops secrets and the home Wi-Fi profile
    inputs.private-nix-config.nixosModules.homerpilab-secrets
    inputs.private-nix-config.nixosModules.homerpilab-shares
  ];

  networking.hostName = "homerpilab";

  # Backup target for homeserver's restic jobs. Append-only, so a compromised
  # client can add snapshots but never delete or rewrite them. No firewall
  # port: clients reach it over tailscale0, which is trusted.
  services.restic.server = {
    enable = true;
    appendOnly = true;
    # Each htpasswd user only sees /<user>/
    privateRepos = true;
    htpasswd-file = config.sops.secrets."restic-htpasswd".path;
  };

  # Retention runs here, against the repo on disk (rest-server can't delete
  # in append-only mode). No paths: the module then only does forget/prune
  # and check. Runs as `restic` so new files stay readable by rest-server.
  services.restic.backups.homeserver-prune = {
    user = "restic";
    repository = "${config.services.restic.server.dataDir}/homeserver";
    passwordFile = config.sops.secrets."restic-password".path;
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
    checkOpts = [ "--read-data-subset=5%" ];
    timerConfig = {
      OnCalendar = "Sun 04:00";
      Persistent = true;
    };
  };

  # Harmonia binary cache for the other hosts: see the home-cache module

  # Samba shares, their directories and users come from
  # private-nix-config.homerpilab-shares. Passwords are not declarative:
  # `sudo smbpasswd -a <user>`.

  system.stateVersion = "26.05";
}
