{ pkgs, ... }:
{
  imports = [
    ./global
  ];

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
