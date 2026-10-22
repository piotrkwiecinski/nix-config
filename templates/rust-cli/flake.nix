{
  description = "rust-cli-template: a Rust command-line tool";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    crane.url = "github:ipetkov/crane";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      crane,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      # Re-exports the package built below rather than calling package.nix
      # with the consumer's nixpkgs: the crate needs the Rust from this
      # flake's nixos-unstable, which a stable-channel nixpkgs may not have
      # yet, and the dependency build stays keyed on this flake's lock alone.
      flake.overlays.default = final: _prev: {
        rust-cli-template = self.packages.${final.stdenv.hostPlatform.system}.default;
      };

      perSystem =
        { system, ... }:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          craneLib = crane.mkLib pkgs;

          rust-cli-template = pkgs.callPackage ./nix/package.nix { inherit craneLib; };

          # nixpkgs' cargo-llvm-cov 0.9.0 fails its own check phase; skip it.
          cargo-llvm-cov = pkgs.cargo-llvm-cov.overrideAttrs { doCheck = false; };
        in
        {
          packages.default = rust-cli-template;

          checks = {
            package = rust-cli-template;
          }
          // rust-cli-template.passthru.checks;

          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.rustc
              pkgs.cargo
              pkgs.clippy
              pkgs.rustfmt
              pkgs.rust-analyzer
              pkgs.cargo-nextest
              cargo-llvm-cov
              pkgs.cargo-audit
            ];
            RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
            # cargo-llvm-cov needs the LLVM tools rustc was built against.
            LLVM_COV = "${pkgs.rustc.unwrapped.llvm}/bin/llvm-cov";
            LLVM_PROFDATA = "${pkgs.rustc.unwrapped.llvm}/bin/llvm-profdata";
          };

          formatter = pkgs.nixfmt;
        };
    };
}
