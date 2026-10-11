{
  lib,
  craneLib,
}:

let
  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../Cargo.toml
      ../Cargo.lock
      ../clippy.toml
      ../.cargo
      ../src
      ../tests
    ];
  };

  commonArgs = {
    inherit src;
    strictDeps = true;
  };

  # Dependencies live in their own derivations, keyed on Cargo.lock and the
  # toolchain, so a source change only recompiles this crate.
  #
  # Release build only: no `cargo check` pass and no dev-dependencies, which
  # the installed binary never needs.
  cargoArtifacts = craneLib.buildDepsOnly (
    commonArgs
    // {
      doCheck = false;
      buildPhaseCargoCommand = "cargoWithProfile build --locked";
    }
  );

  # Adds the dev-dependencies and check metadata the checks below reuse.
  testCargoArtifacts = craneLib.buildDepsOnly commonArgs;
in
craneLib.buildPackage (
  commonArgs
  // {
    inherit cargoArtifacts;

    # Tests run in passthru.checks (`nix flake check`), not on every install.
    doCheck = false;

    passthru.checks = {
      clippy = craneLib.cargoClippy (
        commonArgs
        // {
          cargoArtifacts = testCargoArtifacts;
          cargoClippyExtraArgs = "--all-targets -- -D warnings";
        }
      );

      nextest = craneLib.cargoNextest (
        commonArgs
        // {
          cargoArtifacts = testCargoArtifacts;
        }
      );

      # nextest does not run doctests; the `# Examples` in the docs are tests.
      doctest = craneLib.cargoDocTest (
        commonArgs
        // {
          cargoArtifacts = testCargoArtifacts;
        }
      );

      # Broken intra-doc links and other rustdoc warnings fail the build.
      doc = craneLib.cargoDoc (
        commonArgs
        // {
          cargoArtifacts = testCargoArtifacts;
          cargoDocExtraArgs = "--no-deps";
          RUSTDOCFLAGS = "-D warnings";
        }
      );
    };

    meta = {
      description = "A Rust command-line tool";
      mainProgram = "rust-cli-template";
      platforms = lib.platforms.linux;
    };
  }
)
