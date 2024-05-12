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
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = { self, nixpkgs, home-manager, treefmt-nix, systems, ... } @ inputs: let
    inherit (self) outputs;
    lib = nixpkgs.lib // home-manager.lib;
    forEachSystem = nixpkgs.lib.genAttrs (import systems);
    treefmtEval = forEachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
  in {
    inherit lib;

    overlays = import ./overlays { inherit inputs; };

    devShells = forEachSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in import ./shell.nix { inherit pkgs; }
    );

    formatter = forEachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);

    checks = forEachSystem (pkgs: {
      formatting = treefmtEval.${pkgs.system}.config.build.check self;
    });

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
