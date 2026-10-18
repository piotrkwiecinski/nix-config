{ ... }:
{
  # Reusable NixOS modules. `base` is added to every host by mkHost; hosts
  # pick profiles and features through `outputs.nixosModules.<name>`.
  flake.nixosModules = {
    base = ../modules/nixos/base.nix;
    server = ../modules/nixos/profiles/server.nix;
    desktop = ../modules/nixos/profiles/desktop.nix;
    rpi4 = ../modules/nixos/profiles/rpi4.nix;
    samba = ../modules/nixos/features/samba.nix;
    wifi-watchdog = ../modules/nixos/features/wifi-watchdog.nix;
    home-cache = ../modules/nixos/features/home-cache.nix;
  };
}
