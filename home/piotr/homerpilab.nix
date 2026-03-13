{ pkgs, lib, ... }:
{
  imports = [
    ./global
  ];

  # Disable desktop-specific features for server
  xdg.mime.enable = lib.mkForce false;

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
