{ pkgs, outputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    outputs.nixosModules.server
    outputs.nixosModules.desktop
  ];

  networking.hostName = "homelab";

  boot.kernelPackages = pkgs.linuxPackages;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  virtualisation.docker.enable = true;
  users.extraGroups.docker.members = [ "piotr" ];

  # Reinstalled on the HDD, so this starts from the current release
  system.stateVersion = "26.05";
}
