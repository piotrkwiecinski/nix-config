# Shared base for the headless Raspberry Pi 4B servers (homeserver,
# homerpilab): USB-disk boot via U-Boot, mainline kernel, remote builds on the
# thinkpad, SSH + Tailscale. Host-specific services stay in hosts/<name>.
{
  config,
  pkgs,
  inputs,
  outputs,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.hardware.nixosModules.raspberry-pi-4
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    ../../users/piotr
    ./wifi-watchdog.nix
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

  # nixos-hardware's firmware module replaces the sd-image firmware partition;
  # without U-Boot the Pi firmware has no kernel= to load (black screen)
  hardware.raspberry-pi.firmware.uboot.enable = true;

  # Mainline kernel is in cache.nixos.org; the nixos-hardware vendor kernel
  # (linux-rpi) is not and takes hours to build
  boot.kernelPackages = pkgs.linuxPackages;

  # Headless: vc4 HDMI audio defers forever on the firmware DT + mainline
  # kernel (-EPROBE_DEFER on the DMA channel), so vc4 rebinds in a loop and
  # blanks the console. U-Boot's simple-framebuffer still gives a text console.
  boot.blacklistedKernelModules = [ "vc4" ];

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

  networking.networkmanager = {
    enable = true;
    # brcmfmac power-save wedges the SDIO bus on the Pi 4 (see wifi-watchdog.nix)
    wifi.powersave = false;
  };

  time.timeZone = "Europe/Rome";

  # No RTC: after a long power-off the clock lags and DoH/TLS-dependent DNS
  # fails (cert "not yet valid"), so DNS-named NTP servers may never resolve.
  # Plain NTP by IP needs neither DNS nor valid certs.
  networking.timeServers = [
    "162.159.200.1" # time.cloudflare.com
    "162.159.200.123" # time.cloudflare.com
    "216.239.35.0" # time.google.com
    "216.239.35.4" # time.google.com
  ];

  i18n.defaultLocale = "en_GB.UTF-8";

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Firewall (hosts add their own service ports)
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
}
