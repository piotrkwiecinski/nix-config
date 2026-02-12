{
  pkgs,
  inputs,
  outputs,
  lib,
  ...
}:
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
  ];

  nixpkgs.overlays = [ outputs.overlays.default ];

  environment.systemPackages = with pkgs; [
    # -- Editor & AI --
    unstable.emacs30-pgtk
    master.claude-code-bin
    git

    # -- Nix tooling --
    nil
    nix-output-monitor
    nixfmt-rfc-style

    # -- Disk & filesystem --
    disko
    btrfs-progs
    parted
    gptfdisk
    dosfstools

    # -- Secrets & security --
    sops
    age
    ssh-to-age

    # -- General utilities --
    ripgrep
    htop
    jq
    rsync
    pciutils
    usbutils
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  image.baseName = lib.mkForce "nixos-setup";
}
