# Shared base for the headless Raspberry Pi 4B servers (homeserver,
# homerpilab): USB-disk boot via U-Boot, mainline kernel, remote builds on the
# thinkpad, Wi-Fi recovery. Host-specific services stay in hosts/<name>.
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.hardware.nixosModules.raspberry-pi-4
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    ./server.nix
    ../features/wifi-watchdog.nix
  ];

  # Boot loader for Raspberry Pi
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # nixos-hardware's firmware module replaces the sd-image firmware partition;
  # without U-Boot the Pi firmware has no kernel= to load (black screen)
  hardware.raspberry-pi.firmware.uboot.enable = true;

  # Mainline kernel is in cache.nixos.org; the nixos-hardware vendor kernel
  # (linux-rpi) is not and takes hours to build
  boot.kernelPackages = pkgs.linuxPackages;

  # Headless: vc4 HDMI audio defers forever on the firmware DT + mainline
  # kernel (-EPROBE_DEFER on the DMA channel), so vc4 rebinds in a loop and
  # blanks the console. U-Boot's simple-framebuffer still gives a text console.
  boot.blacklistedKernelModules = [ "vc4" ];

  nix = {
    settings = {
      builders-use-substitutes = true;
      max-jobs = 4;
    };

    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "thinkpad-x1-g3.local";
        sshUser = "builder";
        sshKey = config.sops.secrets."builder-key".path;
        system = "aarch64-linux";
        protocol = "ssh-ng";
        maxJobs = 8;
        speedFactor = 10;
        supportedFeatures = [
          "nixos-test"
          "big-parallel"
          "kvm"
        ];
      }
    ];
  };

  # The thinkpad is the remote builder (over mDNS) and homeserver's backup
  # target (over Tailscale); pin its host key instead of trusting on first use.
  programs.ssh.knownHosts.thinkpad-x1-g3 = {
    hostNames = [
      "thinkpad-x1-g3"
      "thinkpad-x1-g3.local"
    ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGuvmI3g8KhNa3ZQBtCuqHXMRatB+1SeqXesixRVCMHj";
  };

  # brcmfmac power-save wedges the SDIO bus on the Pi 4 (see wifi-watchdog.nix)
  networking.networkmanager.wifi.powersave = false;

  # No RTC: after a long power-off the clock lags and DoH/TLS-dependent DNS
  # fails (cert "not yet valid"), so DNS-named NTP servers may never resolve.
  # Plain NTP by IP needs neither DNS nor valid certs.
  networking.timeServers = [
    "162.159.200.1" # time.cloudflare.com
    "162.159.200.123" # time.cloudflare.com
    "216.239.35.0" # time.google.com
    "216.239.35.4" # time.google.com
  ];

  # Passwordless sudo for wheel group
  security.sudo.wheelNeedsPassword = false;
}
