{
  lib,
  pkgs,
  config,
  inputs,
  outputs,
  ...
}:
{
  imports = [ ./git.nix ];

  nix = {
    package = lib.mkDefault pkgs.unstable.nixVersions.latest;
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "auto-allocate-uids"
        "nix-command"
        "flakes"
      ];

      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
  };

  nixpkgs = {
    overlays = [
      inputs.emacs-overlay.overlays.default
      outputs.overlays.default
    ];
  };

  news.display = "silent";

  xdg.mime.enable = true;

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";

  programs.obs-studio = {
    enable = true;
    package = (
      pkgs.obs-studio.override {
        cudaSupport = true;
      }
    );
    plugins = with pkgs.unstable.obs-studio-plugins; [
      wlrobs
      obs-pipewire-audio-capture
    ];
  };

  home = {
    username = lib.mkDefault "piotr";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "23.11";
  };
}
