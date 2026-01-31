{ inputs, self, ... }:
let
  mkHost =
    hostname:
    inputs.nixpkgs.lib.nixosSystem {
      modules = [ ../hosts/${hostname} ];
      specialArgs = {
        inherit inputs;
        outputs = self;
      };
    };
in
{
  flake.nixosConfigurations = {
    homelab = mkHost "homelab";
    thinkpad-x1-g3 = mkHost "thinkpad-x1-g3";
  };
}
