{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

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

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    private-nix-config.url = "git+ssh://pkgithub/piotrkwiecinski/nix-config-private";

    claude-code-overlay.url = "github:ryoppippi/claude-code-overlay";
    magento-overlay.url = "github:codemanufacture/magento-package-overlay";
    opencode-nix.url = "github:dan-online/opencode-nix";
    codex-overlay.url = "github:sadjow/codex-cli-nix";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.treefmt-nix.flakeModule
        ./parts/dev-shell.nix
        ./parts/formatter.nix
        ./parts/overlays.nix
        ./parts/packages.nix
        ./parts/nixos.nix
        ./parts/home-manager.nix
        ./parts/iso.nix
      ];

      systems = import inputs.systems;
    };
}
