# Always-on hosts reachable over SSH and Tailscale.
{ config, lib, ... }:
let
  authKey = config.sops.secrets."tailscale-auth-key" or null;
in
{
  # The auth key is an OAuth client secret: it never expires, but the nodes it
  # registers must carry a tag the client is allowed to assign. Hosts without
  # it in their sops file join with a manual `tailscale up`.
  services.tailscale = lib.mkIf (authKey != null) {
    authKeyFile = authKey.path;
    authKeyParameters.preauthorized = true;
    extraUpFlags = [ "--advertise-tags=tag:server" ];
  };

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
  };

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
}
