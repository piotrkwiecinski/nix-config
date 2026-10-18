{
  config,
  inputs,
  outputs,
  ...
}:
{
  imports = [
    outputs.nixosModules.rpi4
    outputs.nixosModules.samba
    ./hardware-configuration.nix
    inputs.private-nix-config.nixosModules.homerpilab-secrets
    inputs.private-nix-config.nixosModules.homerpilab-shares
  ];

  networking.hostName = "homerpilab";

  # Home Wi-Fi. The PSK comes from sops, which only decrypts once the host key
  # is enrolled; first boot uses a keyfile with the same UUID written to
  # /etc/NetworkManager/system-connections by hand, which this profile then
  # shadows.
  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.secrets."wifi-env".path ];
    profiles.Kvi4TKi = {
      connection = {
        id = "Kvi4TKi";
        uuid = "71afe599-2af9-47fd-b08f-7c609dfb0c59";
        type = "wifi";
      };
      wifi = {
        mode = "infrastructure";
        ssid = "Kvi4TKi";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "$KVI4TKI_PSK";
      };
      ipv4.method = "auto";
      ipv6.method = "auto";
    };
  };

  # Samba shares, their directories and users come from
  # private-nix-config.homerpilab-shares. Passwords are not declarative:
  # `sudo smbpasswd -a <user>`.

  system.stateVersion = "26.05";
}
