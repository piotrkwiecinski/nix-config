# Samba server discoverable from Windows (wsdd), GNOME/gvfs and macOS (mDNS).
# Hosts define the shares themselves.
{ config, pkgs, ... }:
{
  services.samba = {
    enable = true;
    openFirewall = true;
    settings.global = {
      workgroup = "WORKGROUP";
      "server string" = config.networking.hostName;
      security = "user";
      "map to guest" = "never";
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  # mDNS so <host>.local resolves on the LAN. nixpkgs builds samba without
  # mDNS, so advertise _smb._tcp statically.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
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
}
