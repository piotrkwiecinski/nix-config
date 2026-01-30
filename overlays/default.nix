{ inputs, ... }:
let
  inherit (builtins) readDir attrNames filter;

  additions = final: _prev: import ../pkgs final.pkgs;

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };

  # When applied, the master nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.master'
  master-packages = final: _prev: {
    master = import inputs.nixpkgs-master {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };

  # Auto-discover all .nix files in modifications/
  modificationsDir = ./modifications;
  modificationFiles = filter (n: n != "default.nix" && builtins.match ".*\\.nix" n != null) (
    attrNames (readDir modificationsDir)
  );

  # Import each modification file and compose them
  modifications = map (f: import (modificationsDir + "/${f}") { inherit inputs; }) modificationFiles;

  # Compose all modifications into a single overlay
  composeModifications =
    mods: final: prev:
    builtins.foldl' (acc: mod: acc // (mod final (prev // acc))) { } mods;
in
{
  default =
    final: prev:
    let
      base = (additions final prev) // (unstable-packages final prev) // (master-packages final prev);
      allMods = composeModifications modifications final (prev // base);
    in
    base // allMods;
}
