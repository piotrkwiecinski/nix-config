# Interactive machines with a desktop session.
{ pkgs, ... }:
{
  imports = [
    ../global
    ../features/emacs
    ../features/direnv.nix
    ../features/desktop/common/firefox.nix
  ];

  xdg.mime.enable = true;

  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    fira-code
    fira-code-symbols
  ];
}
