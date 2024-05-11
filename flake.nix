{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default-linux";
    hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows ="nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, systems, ... } @ inputs: let
    inherit (self) outputs;
    lib = nixpkgs.lib // home-manager.lib;
    forEachSystem = f: lib.getAttrs (import systems) (system: f pkgsFor.${system});
    pkgsFor = lib.getAttrs (import systems) (
      system:
        import nixpkgs {
	  inherit system;
	  config.allowUnfree = true;
	}
    );    
  in {
    inherit lib;

    devShells = forEachSystem (pkgs: import ./shell.nix {inherit pkgs;});

    nixosConfigurations = {
      homelab = lib.nixosSystem {
        modules = [./hosts/homelab];      
        specialArgs = {
	  inherit inputs outputs;
	};
      };
    };

   homeConfigurations = {
     "piotr@homelab" = lib.homeManagerConfiguration {
       modules = [./home/piotr/homelab.nix];
       pkgs = nixpkgs.legacyPackages.x86_64-linux;
       extraSpecialArgs = {
         inherit inputs outputs;
       };
     };
   };
  };
}
