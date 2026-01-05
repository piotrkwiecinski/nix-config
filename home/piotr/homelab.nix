{ pkgs, ... }:
{
  imports = [
    ./global
    ./features/emacs
    ./features/direnv.nix
    ./features/desktop/common/firefox.nix
  ];

  home.packages = with pkgs; [
    nodejs_20
    htop
    fira-code
    fira-code-symbols
    nerd-fonts.fira-code
    jq
    unstable.devenv
    unstable.element-desktop
    unstable.signal-desktop
    unstable.slack
    unstable.spotify
    unstable.jetbrains.idea
    inkscape
    gimp
    yt-dlp
    openvpn
  ];

  programs.bash = {
    enable = true;
    enableCompletion = true;
  };

  fonts.fontconfig.enable = true;
}
