{
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
    };

    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "thinkpad-x1-g3.local";
        sshUser = "builder";
        sshKey = "/etc/nix/builder_key";
        system = "aarch64-linux";
        protocol = "ssh-ng";
        maxJobs = 4;
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
    allowedTCPPorts = [
      22 # SSH
      53 # DNS (Blocky)
      80 # HTTP (nginx/Nextcloud)
      443 # HTTPS
      8123 # Home Assistant
      4000 # Blocky API
    ];
    allowedUDPPorts = [
      53 # DNS (Blocky)
    ];
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
      adminpassFile = "/run/secrets/nextcloud-admin-pass";
      dbtype = "pgsql";
    };
    database.createLocally = true;
    configureRedis = true;
    maxUploadSize = "10G";
    settings.trusted_domains = [
      "homeserver.local"
      "homeserver"
      "192.168.68.106"
    ];
  };

  services.nginx.virtualHosts."homeserver.local" = {
    listen = [
      {
        addr = "0.0.0.0";
        port = 80;
      }
    ];
  };

  # Home Assistant
  services.home-assistant = {
    enable = true;
    extraComponents = [
      "default_config"
      "met"
      "esphome"
      "zha"
    ];
    config = {
      homeassistant = {
        name = "Home";
        unit_system = "metric";
        time_zone = "Europe/Rome";
      };
      http = {
        server_port = 8123;
      };
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

  # Passwordless sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Disable sleep/suspend on server
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  users.users."piotr".openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1AkWOqdmzCuLtD1hbJHNbli12oqco1Zh8BHf1tif7zFAz6sNgkFGSp4+gySMIBv+Qk2SbNpGCI1XL2kpgTFUu2LbF3tfOjdP5uXGZfb1Af+rv/ESprBJjjiM8YuvD1TZ4Q25ie1eIyjcey30JJReA4K9nvHPr/nthpch7xfgnoO7Pkyf1OlEeZbp1Luo1s8mqb+oFYW9mcIfDzn5R7YvPshfflMQMXfbgXQ4usKpLNNrr5NjKpBETu9/wf/T9OUD/+2BFyiMrRZkJWtM3QCoXEYDWqcW0qvc4uSXMUyCYbHNtrxuhU1VIbDXDx2Gmkcs58NPnpxw9ONdkA5XS2pfEihElYNc8jF7uh24mjs1MICFZqFgsWWz6S9bYkqW1y/MDuhKy8IA2vdHiSFxVZbSFv6jf8LMQXDbxIHNhGoF8wTJCK/zNRtmOmSQnzi1DQcncYxy0WqoHTlR/beiPqtyaUNSEEyapr9vwagePvuY/4BKMTpamfEe/nGADJpBfcvs= piotr@piotr-laptop"
  ];

  system.stateVersion = "25.11";
}
