# KeePassXC 2.8.0 (Qt6, Wayland auto-type, polkit quick unlock) from
# https://github.com/NixOS/nixpkgs/pull/577117 until it reaches the channel.
{ inputs }:
final: prev: {
  keepassxc = final.callPackage ./keepassxc/package.nix { };
}
