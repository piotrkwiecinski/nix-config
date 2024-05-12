{ pkgs, ... }:
{
  projectRootFile = "flake.nix";
  programs.nixfmt-rfc-style.enable = true;
  settings.formatter.nixpkgs-fmt.excludes = [ "hardware-configuration-*.nix" ];
}
