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
    inputs.disko.nixosModules.disko
    ./disk-config.nix
    inputs.home-manager.nixosModules.home-manager
    ./hardware-configuration.nix
    ../../users/piotr
    inputs.private-nix-config.nixosModules.discourse-secrets
  ];

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [ outputs.overlays.default ];
  };

  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = { inherit inputs outputs; };

  networking.hostName = "discourse";

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = "nix-command flakes";
      trusted-users = [
        "root"
        "piotr"
      ];
      extra-substituters = [ "https://nix-community.cachix.org" ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    registry.nixpkgs.flake = inputs.nixpkgs;
  };

  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_GB.UTF-8";

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22 # SSH
      80 # HTTP (ACME challenge + redirect)
      443 # HTTPS
    ];
  };

  # Fail2ban
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
  };

  # ACME / Let's Encrypt
  security.acme = {
    acceptTerms = true;
    defaults.email = "piotr.kwiecinski@codemanufacture.com";
  };

  # Discourse
  services.discourse = {
    enable = true;
    hostname = "community.codemanufacture.com";
    database.createLocally = true;
    database.ignorePostgresqlVersion = true;
    secretKeyBaseFile = config.sops.secrets."discourse-secret-key-base".path;
    admin = {
      email = "piotr.kwiecinski@codemanufacture.com";
      username = "admin";
      fullName = "Piotr";
      passwordFile = config.sops.secrets."discourse-admin-pass".path;
    };
    mail = {
      notificationEmailAddress = "noreply@codemanufacture.com";
      contactEmailAddress = "piotr.kwiecinski@codemanufacture.com";
      outgoing = {
        serverAddress = "email-smtp.eu-west-1.amazonaws.com";
        port = 587;
        username = "AKIAWZ4AMUABORGSD272";
        passwordFile = config.sops.secrets."discourse-smtp-password".path;
        authentication = "plain";
        forceTLS = true;
        domain = "codemanufacture.com";
      };
    };
    sidekiqProcesses = 1;
    unicornTimeout = 60;
    nginx.enable = true;
  };

  # Nginx with ACME
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    recommendedGzipSettings = true;

    virtualHosts."community.codemanufacture.com" = {
      enableACME = true;
      forceSSL = true;
    };
  };

  # Swap for memory pressure relief (4GB RAM is tight for Discourse)
  swapDevices = [
    {
      device = "/swapfile";
      size = 2048;
    }
  ];

  # User config
  users.users."piotr" = {
    hashedPasswordFile = config.sops.secrets."piotr-password-hash".path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPlX+YupoTzwRASKq0nZV1l+pInQLHsiBmWTP6OdQSGp piotr@thinkpad-x1-g3"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  # Disable sleep/suspend on server
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  system.stateVersion = "25.11";
}
