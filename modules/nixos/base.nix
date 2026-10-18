# Shared by every host (injected by mkHost in parts/nixos.nix): nixpkgs and
# home-manager wiring, nix daemon settings, the piotr user, locale, SSH,
# resolved and Tailscale. Profiles and hosts only add on top of this.
{
  inputs,
  outputs,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./features/user-piotr.nix
  ];

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      inputs.emacs-overlay.overlays.default
      outputs.overlays.default
    ];
  };

  # One pkgs instance for system and home: home-manager would otherwise
  # re-import nixpkgs (and the unstable/cuda sets the overlay pulls in).
  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs outputs; };
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      trusted-users = [
        "root"
        "piotr"
      ];
      extra-substituters = [ "https://nix-community.cachix.org" ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    # Flakes only; nixosSystem already pins the nixpkgs registry entry and
    # NIX_PATH to this flake's nixpkgs.
    channel.enable = false;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_GB.UTF-8";

  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      # With UsePAM this would still accept passwords via PAM
      KbdInteractiveAuthentication = false;
    };
  };

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

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
