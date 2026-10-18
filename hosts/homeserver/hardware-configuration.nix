{
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Raspberry Pi 4B with USB SSD boot
  # Use mkForce to override SD image module defaults that include unavailable modules
  boot.initrd.availableKernelModules = lib.mkForce [
    "usbhid"
    "usb_storage"
    "pcie_brcmstb"
    "reset-raspberrypi"
  ];

  # Root filesystem on USB SSD
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  fileSystems."/boot/firmware" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 4096;
    }
  ];

  hardware.enableRedistributableFirmware = true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
