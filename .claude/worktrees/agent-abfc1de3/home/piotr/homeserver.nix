{ pkgs, lib, ... }:
{
  imports = [
    ./global
  ];

  # Disable desktop-specific features for server
  programs.obs-studio.enable = lib.mkForce false;
  xdg.mime.enable = lib.mkForce false;

  home.packages = with pkgs; [
    btop
    htop
    jq
    tree
  ];

  programs.bash = {
    enable = true;
    enableCompletion = true;
  };
}
