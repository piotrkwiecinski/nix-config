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
      additions = import ../pkgs final.pkgs;
      unstable = {
        unstable = import inputs.nixpkgs-unstable {
          inherit (final.stdenv.hostPlatform) system;
          config.allowUnfree = true;
        };
      };
      master = {
        master = import inputs.nixpkgs-master {
          inherit (final.stdenv.hostPlatform) system;
          config.allowUnfree = true;
        };
      };
      base = additions // unstable // master;
    in
    base // (composeModifications modifications final (prev // base));
}
