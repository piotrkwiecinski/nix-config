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
    outputs.nixosModules.rpi4
    outputs.nixosModules.samba
    outputs.nixosModules.home-cache
    ./hardware-configuration.nix
    ./backup.nix
    inputs.private-nix-config.nixosModules.homeserver-secrets
    # Samba shares and users, Paperless tailnet hostnames
    inputs.private-nix-config.nixosModules.homeserver
  ];

  networking.hostName = "homeserver";

  # LAN gets only the HTTPS vhosts (SSH, Samba and Tailscale are opened by
  # their modules). Everything else (Tailscale HTTPS on 8443/8444/8447) is
  # reached over tailscale0, which is a trusted interface.
  networking.firewall.allowedTCPPorts = [
    80 # HTTP (redirect to HTTPS)
    443 # HTTPS (LAN subdomains)
  ];

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

  # Samba shares and their users come from private-nix-config.homeserver;
  # server, wsdd and mDNS from the samba module.

  # Paperless-ngx document management. Allowed hosts, CSRF origins and the
  # Gmail OAuth client come from private-nix-config.homeserver.
  services.paperless = {
    enable = true;
    # nginx proxies to it; nothing else needs to reach it
    address = "127.0.0.1";
    database.createLocally = true;
    passwordFile = config.sops.secrets."paperless-admin-pass".path;
    exporter = {
      enable = true;
      onCalendar = "*-*-* 23:00:00";
    };
    settings = {
      PAPERLESS_ADMIN_USER = "admin";
      PAPERLESS_URL = "https://paperless.homeserver.local";
      PAPERLESS_PROXY_SSL_HEADER = [
        "HTTP_X_FORWARDED_PROTO"
        "https"
      ];
      PAPERLESS_EMAIL_TASK_CRON = "*/10 * * * *";
    };
    environmentFile = config.sops.secrets."paperless-gmail-oauth-secret".path;
  };

  # restic backups (and homeserver-restore) to the append-only rest-server
  # on homerpilab, over Tailscale; see backup.nix
  homeserver.backup = {
    repositoryFile = config.sops.secrets."restic-repository".path;
    passwordFile = config.sops.secrets."restic-password".path;
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

  system.stateVersion = "26.05";
}
