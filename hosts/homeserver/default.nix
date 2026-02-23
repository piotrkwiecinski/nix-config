{
  config,
  pkgs,
  inputs,
  outputs,
  lib,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.hardware.nixosModules.raspberry-pi-4
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    ./hardware-configuration.nix
    ../../users/piotr
    inputs.private-nix-config.nixosModules.homeserver-secrets
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    overlays = [
      outputs.overlays.default
    ];
  };

  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = { inherit inputs outputs; };

  # Boot loader for Raspberry Pi
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  networking.hostName = "homeserver";
  networking.hosts."192.168.68.103" = [ "thinkpad-x1-g3.local" ];

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = "nix-command flakes";
      trusted-users = [
        "root"
        "piotr"
      ];
      builders-use-substitutes = true;
      max-jobs = 1; # Allow trivial local builds, heavy builds go remote
      extra-substituters = [
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "thinkpad-x1-g3.local";
        sshUser = "builder";
        sshKey = config.sops.secrets."builder-key".path;
        system = "aarch64-linux";
        protocol = "ssh-ng";
        maxJobs = 8;
        speedFactor = 10;
        supportedFeatures = [
          "nixos-test"
          "big-parallel"
          "kvm"
        ];
      }
    ];

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    registry.nixpkgs.flake = inputs.nixpkgs;
  };

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Rome";

  i18n.defaultLocale = "en_GB.UTF-8";

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Firewall
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedTCPPorts = [
      22 # SSH
      53 # DNS (Blocky)
      80 # HTTP (nginx/Nextcloud LAN)
      443 # HTTPS (Nextcloud via Tailscale)
      6600 # MPD
      8080 # Calibre server (LAN)
      8096 # Jellyfin (LAN)
      8123 # Home Assistant (LAN)
      8443 # Home Assistant (Tailscale HTTPS)
      8444 # Paperless (Tailscale HTTPS)
      8445 # Calibre (Tailscale HTTPS)
      8446 # Jellyfin (Tailscale HTTPS)
      8600 # MPD HTTP stream
      4000 # Blocky API
      28981 # Paperless-ngx (LAN)
    ];
    allowedUDPPorts = [
      53 # DNS (Blocky)
      41641 # Tailscale
    ];
  };

  # Tailscale VPN
  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."tailscale-auth-key".path;
  };

  # Fail2ban for SSH protection
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
  };

  # Nextcloud
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    hostName = "homeserver.local";
    https = false;
    config = {
      adminuser = "admin";
      adminpassFile = config.sops.secrets."nextcloud-admin-pass".path;
      dbtype = "pgsql";
    };
    database.createLocally = true;
    configureRedis = true;
    maxUploadSize = "10G";
    settings = {
      trusted_domains = [
        "homeserver.local"
        "homeserver"
        "192.168.68.106"
        "homeserver.tailfbbc95.ts.net"
      ];
      trusted_proxies = [ "127.0.0.1" ];
    };
    extraApps = {
      inherit (pkgs.nextcloud32Packages.apps) spreed;
    };
    extraAppsEnable = true;
  };

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    recommendedGzipSettings = true;

    # Existing LAN Nextcloud
    virtualHosts."homeserver.local" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 80;
        }
      ];
    };

    # Nextcloud via Tailscale HTTPS (port 443)
    virtualHosts."nextcloud-tailscale" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 443;
          ssl = true;
        }
      ];
      extraConfig = ''
        ssl_certificate /var/lib/tailscale-certs/homeserver.crt;
        ssl_certificate_key /var/lib/tailscale-certs/homeserver.key;
      '';
      locations."/" = {
        proxyPass = "http://127.0.0.1:80";
        proxyWebsockets = true;
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

    # Jellyfin via Tailscale HTTPS (port 8446)
    virtualHosts."jellyfin-tailscale" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 8446;
          ssl = true;
        }
      ];
      extraConfig = ''
        ssl_certificate /var/lib/tailscale-certs/homeserver.crt;
        ssl_certificate_key /var/lib/tailscale-certs/homeserver.key;
      '';
      locations."/" = {
        proxyPass = "http://127.0.0.1:8096";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_buffering off;
        '';
      };
    };

    # Calibre via Tailscale HTTPS (port 8445)
    virtualHosts."calibre-tailscale" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 8445;
          ssl = true;
        }
      ];
      extraConfig = ''
        ssl_certificate /var/lib/tailscale-certs/homeserver.crt;
        ssl_certificate_key /var/lib/tailscale-certs/homeserver.key;
      '';
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
      };
    };
  };

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
    config = {
      homeassistant = {
        name = "Home";
        unit_system = "metric";
        time_zone = "Europe/Rome";
      };
      http = {
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

  # Blocky DNS ad-blocker (Pi-hole alternative)
  services.blocky = {
    enable = true;
    settings = {
      ports = {
        dns = 53;
        http = 4000;
      };
      upstreams = {
        groups = {
          default = [
            "https://dns.cloudflare.com/dns-query"
            "https://dns.google/dns-query"
          ];
        };
      };
      bootstrapDns = [
        {
          upstream = "https://dns.cloudflare.com/dns-query";
          ips = [
            "1.1.1.1"
            "1.0.0.1"
          ];
        }
      ];
      blocking = {
        denylists = {
          ads = [
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
            "https://adaway.org/hosts.txt"
          ];
          tracking = [
            "https://v.firebog.net/hosts/Easyprivacy.txt"
          ];
        };
        clientGroupsBlock = {
          default = [
            "ads"
            "tracking"
          ];
        };
      };
      caching = {
        minTime = "5m";
        maxTime = "30m";
        prefetching = true;
      };
    };
  };

  # Calibre ebook server
  services.calibre-server = {
    enable = true;
    package = pkgs.unstable.calibre;
    libraries = [ "/var/lib/calibre-server" ];
    host = "0.0.0.0";
    port = 8080;
  };

  # Shared media group and music directory
  users.groups.media = { };
  systemd.tmpfiles.rules = [
    "d /var/lib/music 2775 root media - -"
  ];

  # Jellyfin media server
  services.jellyfin = {
    enable = true;
    openFirewall = false;
  };
  users.users.jellyfin.extraGroups = [ "media" ];

  # MPD music daemon
  services.mpd = {
    enable = true;
    musicDirectory = "/var/lib/music";
    network = {
      listenAddress = "any";
      port = 6600;
    };
    extraConfig = ''
      audio_output {
        type "httpd"
        name "HTTP Stream"
        encoder "lame"
        port "8600"
        bitrate "192"
        format "44100:16:2"
        always_on "yes"
        tags "yes"
      }
    '';
  };
  users.users.mpd.extraGroups = [ "media" ];

  # Passwordless sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Paperless-ngx document management
  services.paperless = {
    enable = true;
    package = pkgs.unstable.paperless-ngx;
    address = "0.0.0.0";
    database.createLocally = true;
    passwordFile = config.sops.secrets."paperless-admin-pass".path;
    exporter = {
      enable = true;
      onCalendar = "*-*-* 23:00:00";
    };
    settings = {
      PAPERLESS_ADMIN_USER = "admin";
      PAPERLESS_URL = "https://homeserver.tailfbbc95.ts.net:8444";
      PAPERLESS_ALLOWED_HOSTS = builtins.concatStringsSep "," [
        "homeserver.tailfbbc95.ts.net"
        "homeserver.local"
        "homeserver"
        "192.168.68.106"
        "localhost"
        "127.0.0.1"
      ];
      PAPERLESS_CSRF_TRUSTED_ORIGINS = builtins.concatStringsSep "," [
        "https://homeserver.tailfbbc95.ts.net:8444"
        "http://homeserver.local:28981"
        "http://homeserver:28981"
        "http://192.168.68.106:28981"
      ];
      PAPERLESS_PROXY_SSL_HEADER = [
        "HTTP_X_FORWARDED_PROTO"
        "https"
      ];
    };
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

  # Tailscale HTTPS certificate provisioning
  systemd.services.tailscale-cert = {
    description = "Provision Tailscale HTTPS certificates";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    before = [ "nginx.service" ];
    wantedBy = [ "multi-user.target" ];
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

    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  # Make nginx wait for certs
  systemd.services.nginx.after = [ "tailscale-cert.service" ];
  systemd.services.nginx.requires = [ "tailscale-cert.service" ];

  # Timer to renew certs weekly (Tailscale certs expire after 90 days)
  systemd.timers.tailscale-cert = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };

  # Disable sleep/suspend on server
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  users.users."piotr" = {
    hashedPasswordFile = config.sops.secrets."piotr-password-hash".path;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1AkWOqdmzCuLtD1hbJHNbli12oqco1Zh8BHf1tif7zFAz6sNgkFGSp4+gySMIBv+Qk2SbNpGCI1XL2kpgTFUu2LbF3tfOjdP5uXGZfb1Af+rv/ESprBJjjiM8YuvD1TZ4Q25ie1eIyjcey30JJReA4K9nvHPr/nthpch7xfgnoO7Pkyf1OlEeZbp1Luo1s8mqb+oFYW9mcIfDzn5R7YvPshfflMQMXfbgXQ4usKpLNNrr5NjKpBETu9/wf/T9OUD/+2BFyiMrRZkJWtM3QCoXEYDWqcW0qvc4uSXMUyCYbHNtrxuhU1VIbDXDx2Gmkcs58NPnpxw9ONdkA5XS2pfEihElYNc8jF7uh24mjs1MICFZqFgsWWz6S9bYkqW1y/MDuhKy8IA2vdHiSFxVZbSFv6jf8LMQXDbxIHNhGoF8wTJCK/zNRtmOmSQnzi1DQcncYxy0WqoHTlR/beiPqtyaUNSEEyapr9vwagePvuY/4BKMTpamfEe/nGADJpBfcvs= piotr@piotr-laptop"
    ];
  };

  system.stateVersion = "25.11";
}
