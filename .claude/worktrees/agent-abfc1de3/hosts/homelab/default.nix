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
    ./hardware-configuration.nix
    ../../users/piotr
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    overlays = [
      outputs.overlays.default
      inputs.emacs-overlay.overlays.default
    ];
  };

  home-manager.extraSpecialArgs = { inherit inputs outputs; };

  nix = {
    settings = {
      auto-optimise-store = true;
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
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs          = true
      keep-derivations      = true
    '';
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  virtualisation.docker.enable = true;
  users.extraGroups.docker.members = [ "piotr" ];

  networking.hostName = "homelab";

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Rome";

  i18n.defaultLocale = "en_GB.UTF-8";

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  #services.xserver = {
  #  layout = "gb";
  #  xkbVariant = "colemak";
  #};

  # Configure console keymap
  console.keyMap = "uk";

  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  system.stateVersion = "23.11";

  users.users."piotr".openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1AkWOqdmzCuLtD1hbJHNbli12oqco1Zh8BHf1tif7zFAz6sNgkFGSp4+gySMIBv+Qk2SbNpGCI1XL2kpgTFUu2LbF3tfOjdP5uXGZfb1Af+rv/ESprBJjjiM8YuvD1TZ4Q25ie1eIyjcey30JJReA4K9nvHPr/nthpch7xfgnoO7Pkyf1OlEeZbp1Luo1s8mqb+oFYW9mcIfDzn5R7YvPshfflMQMXfbgXQ4usKpLNNrr5NjKpBETu9/wf/T9OUD/+2BFyiMrRZkJWtM3QCoXEYDWqcW0qvc4uSXMUyCYbHNtrxuhU1VIbDXDx2Gmkcs58NPnpxw9ONdkA5XS2pfEihElYNc8jF7uh24mjs1MICFZqFgsWWz6S9bYkqW1y/MDuhKy8IA2vdHiSFxVZbSFv6jf8LMQXDbxIHNhGoF8wTJCK/zNRtmOmSQnzi1DQcncYxy0WqoHTlR/beiPqtyaUNSEEyapr9vwagePvuY/4BKMTpamfEe/nGADJpBfcvs= piotr@piotr-laptop"
  ];

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
}
