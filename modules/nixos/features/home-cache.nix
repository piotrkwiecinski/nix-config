# Binary cache on homerpilab. homerpilab serves its store with Harmonia; every
# other host importing this module substitutes from it over Tailscale (port
# 5000 stays closed on the LAN: tailscale0 is a trusted interface).
#
# The signing key keeps its original `homeserver-cache` name: it was moved
# here from homeserver, so already-signed paths stay valid.
{ config, lib, ... }:
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
