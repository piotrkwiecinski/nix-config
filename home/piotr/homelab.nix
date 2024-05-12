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
    fira-code-nerdfont
    jq
    unstable.devenv
    unstable.element-desktop
    unstable.signal-desktop
    unstable.slack
    unstable.spotify
    unstable.jetbrains.idea-ultimate
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
