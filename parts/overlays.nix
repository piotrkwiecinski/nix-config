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
      additions = import ../pkgs {
        pkgs = final.pkgs;
        inherit pkgs-unstable;
      };
      cosmicNames = [
        "cosmic-applets"
        "cosmic-applibrary"
        "cosmic-bg"
        "cosmic-comp"
        "cosmic-design-demo"
        "cosmic-edit"
        "cosmic-ext-applet-caffeine"
        "cosmic-ext-applet-external-monitor-brightness"
        "cosmic-ext-applet-minimon"
        "cosmic-ext-applet-privacy-indicator"
        "cosmic-ext-applet-sysinfo"
        "cosmic-ext-applet-weather"
        "cosmic-ext-calculator"
        "cosmic-ext-ctl"
        "cosmic-ext-tweaks"
        "cosmic-files"
        "cosmic-greeter"
        "cosmic-icons"
        "cosmic-idle"
        "cosmic-initial-setup"
        "cosmic-launcher"
        "cosmic-notifications"
        "cosmic-osd"
        "cosmic-panel"
        "cosmic-player"
        "cosmic-protocols"
        "cosmic-randr"
        "cosmic-reader"
        "cosmic-screenshot"
        "cosmic-session"
        "cosmic-settings"
        "cosmic-settings-daemon"
        "cosmic-store"
        "cosmic-tasks"
        "cosmic-term"
        "cosmic-wallpapers"
        "cosmic-workspaces-epoch"
      ];
      cosmicPackages = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = pkgs-unstable.${name};
        }) cosmicNames
      );
      unstable = {
        unstable = pkgs-unstable;
      };
      master = {
        master = import inputs.nixpkgs-master {
          inherit (final.stdenv.hostPlatform) system;
          config.allowUnfree = true;
        };
      };
      base = additions // cosmicPackages // unstable // master // { inherit claude-code; };
    in
    base // (composeModifications modifications final (prev // base));
}
