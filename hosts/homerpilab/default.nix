{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ../common/rpi4-server.nix
    ./hardware-configuration.nix
    inputs.private-nix-config.nixosModules.homerpilab-secrets
    inputs.private-nix-config.nixosModules.homerpilab-shares
  ];

  networking.hostName = "homerpilab";

  # Home Wi-Fi. The PSK comes from sops, which only decrypts once the host key
  # is enrolled; first boot uses a keyfile with the same UUID written to
  # /etc/NetworkManager/system-connections by hand, which this profile then
  # shadows.
  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.secrets."wifi-env".path ];
    profiles.Kvi4TKi = {
      connection = {
        id = "Kvi4TKi";
        uuid = "71afe599-2af9-47fd-b08f-7c609dfb0c59";
        type = "wifi";
      };
      wifi = {
        mode = "infrastructure";
        ssid = "Kvi4TKi";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "$KVI4TKI_PSK";
      };
      ipv4.method = "auto";
      ipv6.method = "auto";
    };
  };

  # mDNS so homerpilab.local resolves on the LAN
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
    # nixpkgs builds samba without mDNS, so advertise _smb._tcp statically
    # for GNOME/gvfs and macOS (wsdd covers Windows)
    extraServiceFiles.smb = ''
      <?xml version="1.0" standalone='no'?>
      <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
      <service-group>
        <name replace-wildcards="yes">%h</name>
        <service>
          <type>_smb._tcp</type>
          <port>445</port>
        </service>
      </service-group>
    '';
  };

  # A SIGHUP during startup kills avahi before its handlers are installed;
  # systemd counts that as a clean exit and the stale PID file then blocks
  # every later start. The "+" runs the cleanup outside the unit's capability
  # sandbox, which otherwise denies root access to the avahi-owned file.
  systemd.services.avahi-daemon.serviceConfig = {
    Restart = "always";
    RestartSec = "2s";
    ExecStartPre = "-+${pkgs.coreutils}/bin/rm -f /run/avahi-daemon/pid";
  };

  # resolved is the system resolver; tailscale adds MagicDNS as a split-DNS
  # route for the tailnet. mDNS stays with avahi. This also drops openresolv,
  # whose avahi hook SIGHUPs the daemon while it is still starting at boot.
  services.resolved = {
    enable = true;
    settings.Resolve = {
      MulticastDNS = false;
      LLMNR = false;
      DNSSEC = false;
    };
  };

  # Samba file sharing; shares, their directories and users
  # come from private-nix-config.homerpilab-shares. Passwords are not
  # declarative: `sudo smbpasswd -a <user>`.
  services.samba = {
    enable = true;
    openFirewall = true;
    settings.global = {
      workgroup = "WORKGROUP";
      "server string" = "homerpilab";
      security = "user";
      "map to guest" = "never";
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  system.stateVersion = "26.05";
}
