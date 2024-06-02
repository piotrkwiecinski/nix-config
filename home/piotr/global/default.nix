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
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  nixpkgs = {
    overlays = [
      outputs.overlays.unstable-packages
      inputs.emacs-overlay.overlays.default
    ];
  };

  news.display = "silent";

  xdg.mime.enable = true;

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";

  home = {
    username = lib.mkDefault "piotr";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "23.11";
  };
}
