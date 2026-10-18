{
  inputs,
  outputs,
  ...
}:
{
  imports = [
    outputs.nixosModules.rpi4
    outputs.nixosModules.samba
    ./hardware-configuration.nix
    # sops secrets and the home Wi-Fi profile
    inputs.private-nix-config.nixosModules.homerpilab-secrets
    inputs.private-nix-config.nixosModules.homerpilab-shares
  ];

  networking.hostName = "homerpilab";

  # Samba shares, their directories and users come from
  # private-nix-config.homerpilab-shares. Passwords are not declarative:
  # `sudo smbpasswd -a <user>`.

  system.stateVersion = "26.05";
}
