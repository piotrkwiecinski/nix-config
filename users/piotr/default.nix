{ pkgs, config, ... }:
{
  users.users.piotr = {
    isNormalUser = true;
    description = "Piotr Kwiecinski";
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
      "video"
      "plugdev"
    ];
    packages = [ pkgs.home-manager ];
  };

  home-manager.users.piotr = import ../../home/piotr/${config.networking.hostName}.nix;
}
