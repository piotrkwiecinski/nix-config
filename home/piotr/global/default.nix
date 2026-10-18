{
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = [ ./git.nix ];

  # nixpkgs (overlays, unfree) comes from the system: home-manager runs as a
  # NixOS module with useGlobalPkgs.
  nix = {
    package = lib.mkDefault pkgs.unstable.nixVersions.latest;
    settings = {
      experimental-features = [
        "auto-allocate-uids"
        "nix-command"
        "flakes"
      ];

      # Must be extra-*: a plain `substituters` here overrides the system list
      # in /etc/nix/nix.conf for trusted users, silently dropping the per-host
      # caches (cache.nixos-cuda.org, homeserver:5000, emacs-ci, devenv).
      extra-substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];

      extra-trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
  };

  news.display = "silent";

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";

  home = {
    username = lib.mkDefault "piotr";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "23.11";
  };

  home.packages = with pkgs; [
    htop
    jq
    tree
  ];

  programs.bash = {
    enable = true;
    enableCompletion = true;
  };
}
