{
  config,
  pkgs,
  inputs,
  outputs,
  lib,
  ...
}:
let
  lanSslConfig = ''
    ssl_certificate ${config.sops.secrets."homeserver-lan-cert".path};
    ssl_certificate_key ${config.sops.secrets."homeserver-lan-key".path};
  '';
  bluetti-bt = import ./bluetti-bt.nix { inherit pkgs; };
  solarman = import ./solarman.nix { inherit pkgs; };
in
{
  imports = [
    ../common/rpi4-server.nix
    ./hardware-configuration.nix
    inputs.private-nix-config.nixosModules.homeserver-secrets
  ];

  networking.hostName = "homeserver";

  # resolved is the system resolver; tailscale adds MagicDNS as a split-DNS
  # route for the tailnet. mDNS stays with avahi.
  services.resolved = {
    enable = true;
    settings.Resolve = {
      MulticastDNS = false;
      LLMNR = false;
      DNSSEC = false;
    };
  };

  # Firewall (SSH and Tailscale opened in common/rpi4-server.nix)
  networking.firewall = {
    allowedTCPPorts = [
      80 # HTTP (redirect to HTTPS)
      443 # HTTPS (LAN subdomains)
      6600 # MPD
      8443 # Home Assistant (Tailscale HTTPS)
      8444 # Paperless (Tailscale HTTPS)
      8447 # Forgejo (Tailscale HTTPS)
      8600 # MPD HTTP stream
      5000 # Harmonia binary cache (LAN)
      5600 # ActivityWatch aggregator (LAN + Tailscale)
    ];
  };

  # Binary cache for LAN clients (thinkpad fetches pre-built aarch64 paths)
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

  # Tailscale VPN
  services.tailscale = {
    extraSetFlags = [ "--accept-dns=true" ];
  };

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    recommendedGzipSettings = true;

    # HTTP -> HTTPS redirect (catch-all)
    virtualHosts."_redirect" = {
      serverName = "_";
      listen = [
        {
          addr = "0.0.0.0";
          port = 80;
        }
      ];
      extraConfig = ''
        return 301 https://$host$request_uri;
      '';
    };

    # Home Assistant LAN HTTPS
    virtualHosts."hass.homeserver.local" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 443;
          ssl = true;
        }
      ];
      extraConfig = lanSslConfig;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8123";
        proxyWebsockets = true;
      };
    };

    # Paperless LAN HTTPS
    virtualHosts."paperless.homeserver.local" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 443;
          ssl = true;
        }
      ];
      extraConfig = lanSslConfig;
      locations."/" = {
        proxyPass = "http://127.0.0.1:28981";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_read_timeout 300;
          proxy_connect_timeout 300;
          proxy_send_timeout 300;
          client_max_body_size 100M;
        '';
      };
    };

    # Forgejo LAN HTTPS
    virtualHosts."forgejo.homeserver.local" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 443;
          ssl = true;
        }
      ];
      extraConfig = lanSslConfig;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3000";
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 512M;
        '';
      };
    };

    # Home Assistant via Tailscale HTTPS (port 8443)
    virtualHosts."hass-tailscale" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 8443;
          ssl = true;
        }
      ];
      extraConfig = ''
        ssl_certificate /var/lib/tailscale-certs/homeserver.crt;
        ssl_certificate_key /var/lib/tailscale-certs/homeserver.key;
      '';
      locations."/" = {
        proxyPass = "http://127.0.0.1:8123";
        proxyWebsockets = true;
      };
    };

    # Paperless via Tailscale HTTPS (port 8444)
    virtualHosts."paperless-tailscale" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 8444;
          ssl = true;
        }
      ];
      extraConfig = ''
        ssl_certificate /var/lib/tailscale-certs/homeserver.crt;
        ssl_certificate_key /var/lib/tailscale-certs/homeserver.key;
      '';
      locations."/" = {
        proxyPass = "http://127.0.0.1:28981";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_read_timeout 300;
          proxy_connect_timeout 300;
          proxy_send_timeout 300;
          client_max_body_size 100M;
        '';
      };
    };

    # Forgejo via Tailscale HTTPS (port 8447)
    virtualHosts."forgejo-tailscale" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 8447;
          ssl = true;
        }
      ];
      extraConfig = ''
        ssl_certificate /var/lib/tailscale-certs/homeserver.crt;
        ssl_certificate_key /var/lib/tailscale-certs/homeserver.key;
      '';
      locations."/" = {
        proxyPass = "http://127.0.0.1:3000";
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 512M;
        '';
      };
    };

  };

  # Bluetooth (required for Bluetti BLE integration)
  # The nixos-hardware overlay targets the vendor DT (uart0_pins); mainline
  # bcm2711-rpi-4-b.dtb already has the bluetooth node on uart0
  hardware.raspberry-pi."4".bluetooth.enable = false;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Free ttyAMA0 from serial console so Bluetooth can use it
  # (sd-image-aarch64.nix sets console=ttyAMA0 by default)
  boot.kernelParams = lib.mkForce [
    "console=ttyS0,115200n8"
    "console=tty0"
    "nohibernate"
    "loglevel=7"
  ];

  # Home Assistant
  services.home-assistant = {
    enable = true;
    extraComponents = [
      "default_config"
      "met"
      "esphome"
      "zha"
      "wiz"
      "bluetooth"
      "mobile_app"
    ];
    customComponents = [
      bluetti-bt
      solarman
    ];
    config = {
      default_config = { };
      homeassistant = {
        name = "Home";
        unit_system = "metric";
        time_zone = "Europe/Rome";
      };
      http = {
        server_host = "127.0.0.1";
        server_port = 8123;
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
      };
      mobile_app = { };
    };
  };

  # ConBee 2 Zigbee stick — grant HA service access to /dev/ttyACM*
  users.users.hass.extraGroups = [ "dialout" ];

  # The LAN vhosts have no DNS records and mdns4_minimal skips multi-label
  # names, so resolve them locally for services on this host.
  networking.hosts."192.168.68.105" = lib.filter (lib.hasSuffix ".homeserver.local") (
    lib.attrNames config.services.nginx.virtualHosts
  );

  # Forgejo git forge
  services.forgejo = {
    enable = true;
    database.type = "sqlite3";
    lfs.enable = true;
    settings = {
      server = {
        DOMAIN = "forgejo.homeserver.local";
        ROOT_URL = "https://forgejo.homeserver.local/";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 3000;
      };
      service.DISABLE_REGISTRATION = true;
      session.COOKIE_SECURE = true;
      actions.ENABLED = true;
    };
  };

  # Shared media group and music directory
  users.groups.media = { };
  systemd.tmpfiles.rules = [
    "d /var/lib/music 2775 root media - -"
    "d /var/lib/shared 2775 root media - -"
  ];

  # MPD music daemon
  services.mpd = {
    enable = true;
    # 6600/8600 are opened explicitly in networking.firewall.allowedTCPPorts;
    # set false so the module doesn't warn about bind_to_address = "any".
    openFirewall = false;
    settings = {
      music_directory = "/var/lib/music";
      bind_to_address = "any";
      port = 6600;
      audio_output = [
        {
          type = "httpd";
          name = "HTTP Stream";
          encoder = "lame";
          port = "8600";
          bitrate = "192";
          format = "44100:16:2";
          always_on = "yes";
          tags = "yes";
        }
      ];
    };
  };
  users.users.mpd.extraGroups = [ "media" ];

  # Samba file sharing
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "homeserver";
        security = "user";
        "map to guest" = "never";
      };
      music = {
        path = "/var/lib/music";
        browseable = "yes";
        "read only" = "no";
        "valid users" = "piotr gosia";
        "create mask" = "0664";
        "directory mask" = "2775";
        "force group" = "media";
      };
      shared = {
        path = "/var/lib/shared";
        browseable = "yes";
        "read only" = "no";
        "valid users" = "piotr gosia";
        "create mask" = "0664";
        "directory mask" = "2775";
        "force group" = "media";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  # wsdd only reaches Windows; GNOME/gvfs and macOS discover shares via mDNS.
  # nixpkgs builds samba without mDNS, so advertise _smb._tcp statically.
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

  # Paperless-ngx document management
  services.paperless = {
    enable = true;
    address = "0.0.0.0";
    database.createLocally = true;
    passwordFile = config.sops.secrets."paperless-admin-pass".path;
    exporter = {
      enable = true;
      onCalendar = "*-*-* 23:00:00";
    };
    settings = {
      PAPERLESS_ADMIN_USER = "admin";
      PAPERLESS_URL = "https://paperless.homeserver.local";
      PAPERLESS_ALLOWED_HOSTS = builtins.concatStringsSep "," [
        "paperless.homeserver.local"
        "homeserver.tailfbbc95.ts.net"
        "localhost"
        "127.0.0.1"
      ];
      PAPERLESS_CSRF_TRUSTED_ORIGINS = builtins.concatStringsSep "," [
        "https://paperless.homeserver.local"
        "https://homeserver.tailfbbc95.ts.net:8444"
      ];
      PAPERLESS_PROXY_SSL_HEADER = [
        "HTTP_X_FORWARDED_PROTO"
        "https"
      ];
      PAPERLESS_GMAIL_OAUTH_CLIENT_ID = "277222441434-ecser4h8qrin4uu0tiak5cbqolue2rou.apps.googleusercontent.com";
      PAPERLESS_OAUTH_CALLBACK_BASE_URL = "https://homeserver.tailfbbc95.ts.net:8444";
      PAPERLESS_EMAIL_TASK_CRON = "*/10 * * * *";
    };
    environmentFile = config.sops.secrets."paperless-gmail-oauth-secret".path;
  };

  # Paperless backup: compress export and send to thinkpad after successful export
  systemd.services.paperless-exporter.onSuccess = [ "paperless-backup-sync.service" ];

  systemd.services.paperless-backup-sync = {
    description = "Compress and send Paperless export to thinkpad";
    path = with pkgs; [
      gnutar
      zstd
      openssh
      coreutils
    ];
    script = ''
      set -euo pipefail
      EXPORT_DIR="/var/lib/paperless/export"
      BACKUP_DIR="/var/lib/paperless/backup"
      TIMESTAMP=$(date +%Y%m%d)
      ARCHIVE="paperless-''${TIMESTAMP}.tar.zst"
      SSH_KEY="${config.sops.secrets."builder-key".path}"
      SSH_OPTS="-o StrictHostKeyChecking=accept-new"
      REMOTE="builder@thinkpad-x1-g3.local"
      REMOTE_DIR="/data/backups/paperless"

      # Compress export into timestamped archive
      mkdir -p "$BACKUP_DIR"
      tar -C "$EXPORT_DIR" -cf - . | zstd -f -o "$BACKUP_DIR/$ARCHIVE"

      # Verify archive was created and is non-empty
      if [ ! -s "$BACKUP_DIR/$ARCHIVE" ]; then
        echo "ERROR: Archive $BACKUP_DIR/$ARCHIVE is empty or missing"
        exit 1
      fi

      # Send to thinkpad
      ssh -i "$SSH_KEY" $SSH_OPTS "$REMOTE" "mkdir -p $REMOTE_DIR"
      scp -i "$SSH_KEY" $SSH_OPTS "$BACKUP_DIR/$ARCHIVE" "$REMOTE:$REMOTE_DIR/"

      # Cleanup local (keep 3)
      ls -t "$BACKUP_DIR"/paperless-*.tar.zst 2>/dev/null | tail -n +4 | xargs -r rm -f

      # Cleanup remote (keep 3)
      ssh -i "$SSH_KEY" $SSH_OPTS "$REMOTE" \
        "ls -t $REMOTE_DIR/paperless-*.tar.zst 2>/dev/null | tail -n +4 | xargs -r rm -f"
    '';
    serviceConfig.Type = "oneshot";
  };

  # Home Assistant backup: stop HA briefly, compress /var/lib/hass, send to thinkpad
  systemd.timers.hass-backup-sync = {
    description = "Daily Home Assistant backup to thinkpad";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 12:00:00";
      Persistent = true;
    };
  };

  systemd.services.hass-backup-sync = {
    description = "Snapshot Home Assistant state and send to thinkpad";
    path = with pkgs; [
      gnutar
      zstd
      openssh
      coreutils
      systemd
    ];
    script = ''
      set -euo pipefail
      HASS_DIR="/var/lib/hass"
      BACKUP_DIR="/var/lib/hass-backup"
      TIMESTAMP=$(date +%Y%m%d)
      ARCHIVE="hass-''${TIMESTAMP}.tar.zst"
      SSH_KEY="${config.sops.secrets."builder-key".path}"
      SSH_OPTS="-o StrictHostKeyChecking=accept-new"
      REMOTE="builder@thinkpad-x1-g3.local"
      REMOTE_DIR="/data/backups/home-assistant"

      mkdir -p "$BACKUP_DIR"

      # Stop HA for a consistent SQLite snapshot, always restart on exit
      trap 'systemctl start home-assistant.service' EXIT
      systemctl stop home-assistant.service

      tar -C "$HASS_DIR" \
        --exclude='./home-assistant.log*' \
        --exclude='./OZW_Log.txt*' \
        --exclude='./tmp' \
        --exclude='./deps' \
        --exclude='./.cache' \
        -cf - . | zstd -f -o "$BACKUP_DIR/$ARCHIVE"

      systemctl start home-assistant.service
      trap - EXIT

      if [ ! -s "$BACKUP_DIR/$ARCHIVE" ]; then
        echo "ERROR: Archive $BACKUP_DIR/$ARCHIVE is empty or missing"
        exit 1
      fi

      ssh -i "$SSH_KEY" $SSH_OPTS "$REMOTE" "mkdir -p $REMOTE_DIR"
      scp -i "$SSH_KEY" $SSH_OPTS "$BACKUP_DIR/$ARCHIVE" "$REMOTE:$REMOTE_DIR/"

      # Retention: keep 3 locally, 3 remotely
      ls -t "$BACKUP_DIR"/hass-*.tar.zst 2>/dev/null | tail -n +4 | xargs -r rm -f
      ssh -i "$SSH_KEY" $SSH_OPTS "$REMOTE" \
        "ls -t $REMOTE_DIR/hass-*.tar.zst 2>/dev/null | tail -n +4 | xargs -r rm -f"
    '';
    serviceConfig.Type = "oneshot";
  };

  # ActivityWatch aggregator - receives bucket pushes from thinkpad and
  # Android. Port 5600 is reachable from LAN and tailscale0.
  users.users.aw-server = {
    isSystemUser = true;
    group = "aw-server";
    home = "/var/lib/aw-server";
  };
  users.groups.aw-server = { };

  systemd.services.aw-server =
    let
      awConfigHome = pkgs.runCommand "aw-server-config" { } ''
        mkdir -p $out/activitywatch/aw-server-rust
        cat > $out/activitywatch/aw-server-rust/config.toml <<'EOF'
        address = "0.0.0.0"
        port = 5600
        # Allow the web UI served from this same host to call the API.
        # aw-server-rust's default CORS whitelist only covers localhost.
        cors = [
          "http://homeserver:5600",
          "http://homeserver.local:5600",
        ]
        cors_regex = []

        [custom_static]
        EOF
      '';
    in
    {
      description = "ActivityWatch aggregator (aw-server-rust)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.aw-server-rust}/bin/aw-server --host 0.0.0.0 --port 5600";
        User = "aw-server";
        Group = "aw-server";
        StateDirectory = "aw-server";
        Environment = [
          "XDG_DATA_HOME=/var/lib/aw-server"
          "XDG_CONFIG_HOME=${awConfigHome}"
        ];
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

  systemd.timers.aw-backup-sync = {
    description = "Daily ActivityWatch backup to thinkpad";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 13:00:00";
      Persistent = true;
    };
  };

  systemd.services.aw-backup-sync = {
    description = "Snapshot ActivityWatch state and send to thinkpad";
    path = with pkgs; [
      gnutar
      zstd
      openssh
      coreutils
    ];
    script = ''
      set -euo pipefail
      AW_DIR="/var/lib/aw-server"
      BACKUP_DIR="/var/lib/aw-server-backup"
      TIMESTAMP=$(date +%Y%m%d)
      ARCHIVE="aw-server-''${TIMESTAMP}.tar.zst"
      SSH_KEY="${config.sops.secrets."builder-key".path}"
      SSH_OPTS="-o StrictHostKeyChecking=accept-new"
      REMOTE="builder@thinkpad-x1-g3.local"
      REMOTE_DIR="/data/backups/aw-server"

      mkdir -p "$BACKUP_DIR"
      tar -C "$AW_DIR" -cf - . | zstd -f -o "$BACKUP_DIR/$ARCHIVE"

      if [ ! -s "$BACKUP_DIR/$ARCHIVE" ]; then
        echo "ERROR: Archive $BACKUP_DIR/$ARCHIVE is empty or missing"
        exit 1
      fi

      ssh -i "$SSH_KEY" $SSH_OPTS "$REMOTE" "mkdir -p $REMOTE_DIR"
      scp -i "$SSH_KEY" $SSH_OPTS "$BACKUP_DIR/$ARCHIVE" "$REMOTE:$REMOTE_DIR/"

      ls -t "$BACKUP_DIR"/aw-server-*.tar.zst 2>/dev/null | tail -n +4 | xargs -r rm -f
      ssh -i "$SSH_KEY" $SSH_OPTS "$REMOTE" \
        "ls -t $REMOTE_DIR/aw-server-*.tar.zst 2>/dev/null | tail -n +4 | xargs -r rm -f"
    '';
    serviceConfig.Type = "oneshot";
  };

  # Tailscale HTTPS certificate provisioning. nginx must not wait on this: it
  # needs the network up, and during a switch NetworkManager only starts after
  # nginx's restart finishes, so an nginx -> tailscale-cert dependency deadlocks
  # the switch with the network down. nginx starts on whatever cert exists and
  # is reloaded once a fresh one lands.
  systemd.services.tailscale-cert = {
    description = "Provision Tailscale HTTPS certificates";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    restartIfChanged = false;
    path = [
      pkgs.tailscale
      pkgs.jq
    ];
    script = ''
      # Wait for Tailscale to be connected
      until tailscale status --json | jq -e '.Self.Online' > /dev/null 2>&1; do
        sleep 2
      done

      mkdir -p /var/lib/tailscale-certs

      # Get the Tailscale hostname
      TAILSCALE_HOSTNAME=$(tailscale status --json | jq -r '.Self.DNSName | rtrimstr(".")')

      # Fetch certificate from Tailscale (Let's Encrypt)
      tailscale cert \
        --cert-file /var/lib/tailscale-certs/homeserver.crt \
        --key-file /var/lib/tailscale-certs/homeserver.key \
        "$TAILSCALE_HOSTNAME"

      # Set permissions for nginx
      chmod 644 /var/lib/tailscale-certs/homeserver.crt
      chmod 600 /var/lib/tailscale-certs/homeserver.key
      chown nginx:nginx /var/lib/tailscale-certs/*

      # --no-block: never wait on nginx from here
      systemctl --no-block reload-or-restart nginx.service
    '';
    serviceConfig = {
      Type = "oneshot";
      # Not RemainAfterExit: the weekly timer can't re-run an active unit
      TimeoutStartSec = "15min";
    };
  };

  # Self-signed placeholder so nginx's config test passes before the first
  # Tailscale cert is fetched (fresh install, or tailnet not logged in yet)
  systemd.services.tailscale-cert-placeholder = {
    description = "Placeholder Tailscale HTTPS certificate for nginx";
    before = [ "nginx.service" ];
    requiredBy = [ "nginx.service" ];
    path = [ pkgs.openssl ];
    script = ''
      dir=/var/lib/tailscale-certs
      [ -s $dir/homeserver.crt ] && [ -s $dir/homeserver.key ] && exit 0
      mkdir -p $dir
      openssl req -x509 -newkey rsa:2048 -nodes -days 30 -subj /CN=placeholder \
        -keyout $dir/homeserver.key -out $dir/homeserver.crt
      chmod 644 $dir/homeserver.crt
      chmod 600 $dir/homeserver.key
      chown nginx:nginx $dir/*
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  # Timer to renew certs weekly (Tailscale certs expire after 90 days)
  systemd.timers.tailscale-cert = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };

  users.users."piotr" = {
    extraGroups = [ "media" ];
  };

  users.users.gosia = {
    isNormalUser = true;
    shell = "${pkgs.shadow}/bin/nologin";
    extraGroups = [ "media" ];
  };

  system.stateVersion = "26.05";
}
