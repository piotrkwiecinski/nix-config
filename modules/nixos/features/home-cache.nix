# Binary cache on homerpilab. homerpilab serves its store with Harmonia; every
# other host importing this module substitutes from it over Tailscale (port
# 5000 stays closed on the LAN: tailscale0 is a trusted interface).
#
# The signing key keeps the name `homeserver-cache` so paths already signed
# with it stay valid.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  server = "homerpilab";
  isServer = config.networking.hostName == server;
in
lib.mkMerge [
  (lib.mkIf isServer {
    # Static user so the sops secret can be owned by it before harmonia starts
    users.users.harmonia = {
      isSystemUser = true;
      group = "harmonia";
    };
    users.groups.harmonia = { };
    # 26.05 ships 3.1.0, which warns that the 0440 systemd credential holding
    # the signing key is insecure; 3.2.0+ exempts $CREDENTIALS_DIRECTORY
    # (nix-community/harmonia#1074). Drop once stable has >= 3.2.0.
    services.harmonia.package = pkgs.unstable.harmonia;
    services.harmonia.cache = {
      enable = true;
      signKeyPaths = [ config.sops.secrets."harmonia-signing-key".path ];
      settings.bind = "[::]:5000";
    };
  })

  (lib.mkIf (!isServer) {
    nix.settings = {
      extra-substituters = [ "http://${server}:5000?priority=40" ];
      # Fail over to the next cache quickly when homerpilab is off the tailnet
      connect-timeout = lib.mkDefault 5;
    };
  })

  {
    nix.settings.extra-trusted-public-keys = [
      "homeserver-cache:GnyJnLGzLHN2pdm9D6kzkSd3s3IHMb6SNDh0y9Akoz4="
    ];
  }
]
