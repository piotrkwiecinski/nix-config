{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Pinned: nixos-unstable @ 624af66 (2026-07-26) breaks ollama-cuda 0.32.3 —
    # the CUDA setup hook omits cuda_nvcc from CUDAToolkit_ROOT, so ggml's
    # ggml-cuda/CMakeLists.txt fails with "CUDA Toolkit not found".
    # Unpin once ollama-cuda builds again on nixos-unstable.
    nixpkgs-unstable-cuda.url = "github:NixOS/nixpkgs/64c08a7ca051951c8eae34e3e3cb1e202fe36786";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    systems.url = "github:nix-systems/default-linux";
    hardware.url = "github:nixos/nixos-hardware";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
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

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    private-nix-config = {
      url = "git+ssh://pkgithub/piotrkwiecinski/nix-config-private";
      inputs.sops-nix.follows = "sops-nix";
    };

    claude-code-overlay.url = "github:sadjow/claude-code-nix";
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
