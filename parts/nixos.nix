{ inputs, self, ... }:
let
  mkHost =
    {
      hostname,
      system ? "x86_64-linux",
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [ ../hosts/${hostname} ];
      specialArgs = {
        inherit inputs;
        outputs = self;
      };
    };
in
{
  flake.nixosConfigurations = {
    homelab = mkHost { hostname = "homelab"; };
    thinkpad-x1-g3 = mkHost { hostname = "thinkpad-x1-g3"; };
    homeserver = mkHost {
      hostname = "homeserver";
      system = "aarch64-linux";
    };
  };
}
