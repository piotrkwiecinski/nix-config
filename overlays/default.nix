{ inputs, ... }:
let
  additions = final: _prev: import ../pkgs final.pkgs;
  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };
in
{
  default = final: prev: (additions final prev) // (unstable-packages final prev);
}
