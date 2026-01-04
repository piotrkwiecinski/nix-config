{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default-linux";
    hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    private-nix-config = {
      flake = false;
      url = "git+ssh://pkgithub/piotrkwiecinski/nix-config-private";
    };
    calstart = {
      url = "git+ssh://pkgithub/piotrkwiecinski/calstart?ref=main";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      treefmt-nix,
      systems,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib // home-manager.lib;
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
      eachSystem =
        f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs-unstable.legacyPackages.${system});
      treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    in
    {
      inherit lib;

      packages = forEachSystem (system: import ./pkgs nixpkgs.legacyPackages.${system});

      overlays = import ./overlays { inherit inputs; };

      devShells = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./shell.nix { inherit pkgs; }
      );

      formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);

      checks = eachSystem (pkgs: {
        formatting = treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.check self;
      });

      nixosConfigurations = {
        homelab = lib.nixosSystem {
          modules = [ ./hosts/homelab ];
          specialArgs = { inherit inputs outputs; };
        };
        thinkpad-x1-g3 = lib.nixosSystem {
          modules = [ ./hosts/thinkpad-x1-g3 ];
          specialArgs = { inherit inputs outputs; };
        };
      };

      homeConfigurations = {
        "piotr@homelab" = lib.homeManagerConfiguration {
          modules = [ ./home/piotr/homelab.nix ];
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
        };
        "piotr@thinkpad-x1-g3" = lib.homeManagerConfiguration {
          modules = [ ./home/piotr/thinkpad-x1-g3.nix ];
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
        };
      };
    };
}
