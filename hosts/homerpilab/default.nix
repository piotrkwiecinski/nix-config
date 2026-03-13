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
    inputs.private-nix-config.nixosModules.homerpilab-secrets
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

  networking.hostName = "homerpilab";

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = "nix-command flakes";
      trusted-users = [
        "root"
        "piotr"
      ];
      builders-use-substitutes = true;
      max-jobs = 4;
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
    ];
    allowedUDPPorts = [
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

  # mDNS so homerpilab.local resolves on the LAN
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  # Passwordless sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

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
