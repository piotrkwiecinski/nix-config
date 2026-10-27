# Beyond Identity 2.108.0-3 from
# https://github.com/NixOS/nixpkgs/pull/575981 until it reaches the channel.
{ inputs }:
final: prev: {
  beyond-identity = final.callPackage ./beyond-identity/package.nix { };
}
