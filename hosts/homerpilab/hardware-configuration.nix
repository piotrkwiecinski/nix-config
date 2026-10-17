{
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Raspberry Pi 4B booting from a 1TB USB hard drive
  # Use mkForce to override SD image module defaults that include unavailable modules
  boot.initrd.availableKernelModules = lib.mkForce [
    "usbhid"
    "usb_storage"
    "uas" # most USB-SATA bridges; usb_storage refuses UAS devices when uas is a module
    "pcie_brcmstb"
    "reset-raspberrypi"
  ];

  # Root filesystem on the USB drive; the sd-image root partition grows to
  # fill the disk on first boot
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  # Boot partition
  fileSystems."/boot/firmware" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  # 4GB swap file
  swapDevices = [
    {
      device = "/swapfile";
      size = 4096;
    }
  ];

  hardware.enableRedistributableFirmware = true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
