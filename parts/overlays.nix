{ inputs, ... }:
let
  inherit (builtins) readDir attrNames filter;

  modificationsDir = ../overlays/modifications;
  modificationFiles = filter (n: n != "default.nix" && builtins.match ".*\\.nix" n != null) (
    attrNames (readDir modificationsDir)
  );

  modifications = map (f: import (modificationsDir + "/${f}") { inherit inputs; }) modificationFiles;

  composeModifications =
    mods: final: prev:
    builtins.foldl' (acc: mod: acc // (mod final (prev // acc))) { } mods;
in
{
  flake.overlays.default =
    final: prev:
    let
      pkgs-unstable = import inputs.nixpkgs-unstable {
        inherit (final.stdenv.hostPlatform) system;
        config.allowUnfree = true;
        overlays = [ inputs.emacs-overlay.overlays.default ];
      };
      claude-code = (inputs.claude-code-overlay.overlays.default final prev).claude-code;
      magento-pkgs = inputs.magento-overlay.overlays.default final prev;
      additions = import ../pkgs {
        pkgs = final.pkgs;
        inherit pkgs-unstable;
      };
      unstable = {
        unstable = pkgs-unstable;
      };
      base = additions // magento-pkgs // unstable // { inherit claude-code; };
    in
    base // (composeModifications modifications final (prev // base));
}
