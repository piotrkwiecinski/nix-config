{ config, lib, ... }:
let
  # Hosts whose sops file carries the hash get a declarative password; the
  # rest (e.g. a host not yet enrolled in .sops.yaml) keep a mutable one.
  passwordSecret = config.sops.secrets."piotr-password-hash" or null;
in
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
      "input"
      "ydotool"
    ];
    hashedPasswordFile = lib.mkIf (passwordSecret != null) passwordSecret.path;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1AkWOqdmzCuLtD1hbJHNbli12oqco1Zh8BHf1tif7zFAz6sNgkFGSp4+gySMIBv+Qk2SbNpGCI1XL2kpgTFUu2LbF3tfOjdP5uXGZfb1Af+rv/ESprBJjjiM8YuvD1TZ4Q25ie1eIyjcey30JJReA4K9nvHPr/nthpch7xfgnoO7Pkyf1OlEeZbp1Luo1s8mqb+oFYW9mcIfDzn5R7YvPshfflMQMXfbgXQ4usKpLNNrr5NjKpBETu9/wf/T9OUD/+2BFyiMrRZkJWtM3QCoXEYDWqcW0qvc4uSXMUyCYbHNtrxuhU1VIbDXDx2Gmkcs58NPnpxw9ONdkA5XS2pfEihElYNc8jF7uh24mjs1MICFZqFgsWWz6S9bYkqW1y/MDuhKy8IA2vdHiSFxVZbSFv6jf8LMQXDbxIHNhGoF8wTJCK/zNRtmOmSQnzi1DQcncYxy0WqoHTlR/beiPqtyaUNSEEyapr9vwagePvuY/4BKMTpamfEe/nGADJpBfcvs= piotr@piotr-laptop"
    ];
  };

  home-manager.users.piotr = import ../../../home/piotr/${config.networking.hostName}.nix;
}
