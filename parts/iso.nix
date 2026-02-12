{ inputs, self, ... }:
{
  flake.nixosConfigurations.iso = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ ../hosts/iso ];
    specialArgs = {
      inherit inputs;
      outputs = self;
    };
  };
}
