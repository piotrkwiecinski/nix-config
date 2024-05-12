{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows ="nixpkgs";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    copilot-el = {
      url = "github:copilot-emacs/copilot.el";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, systems, ... } @ inputs: let
    inherit (self) outputs;
    lib = nixpkgs.lib // home-manager.lib;
    forEachSystem = nixpkgs.lib.genAttrs (import systems);
    pkgsFor = lib.getAttrs (import systems) (
      system:
        import nixpkgs {
	        inherit system;
	        config.allowUnfree = true;
	      }
    );
  in {
    inherit lib;

    overlays = import ./overlays { inherit inputs; };

    devShells = forEachSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in import ./shell.nix { inherit pkgs; }
    );

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
