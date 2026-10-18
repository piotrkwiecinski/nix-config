{ pkgs, ... }:
{
  imports = [ ./profiles/workstation.nix ];

  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    nerd-fonts.fira-code
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
}
