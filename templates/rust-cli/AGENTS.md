# rust-cli-template

Rust CLI (clap derive). `src/main.rs` only calls `rust_cli_template::run`;
the logic lives in the library so unit tests and doctests reach it.

## Workflow

- Dev shell: `nix develop` (nixpkgs Rust, nextest, llvm-cov, audit).
- TDD: write the failing test first (a unit test in the module, a doctest,
  or a CLI test in `tests/`), watch it fail, then implement.
- Before every commit: `cargo nextest run`, `cargo test --doc` and
  `cargo gate` (clippy `--all-targets -D warnings`; Cargo.toml denies
  all/pedantic/nursery plus unwrap/expect/indexing/arithmetic/`as`).
  Integration test files carry a crate-level `#![allow(...)]` for the
  panicking-in-tests lints.
- `nix flake check` builds the package and runs clippy, nextest, doctests
  and rustdoc with `-D warnings`.

## Documentation

rustdoc is part of the code, and the lints enforce most of it:

- Every module opens with `//!` saying what it is for; every item has `///`.
- Fallible functions have `# Errors`; anything that can panic has `# Panics`.
- Public functions have an `# Examples` doctest. Use `?` (ending with
  `# Ok::<(), rust_cli_template::Error>(())`), never `unwrap`.
- Identifiers in prose are in backticks; link items as [`Item`].
- clap doc comments in `src/cli.rs` are the `--help` text: write them for
  the user.

## Starting a project from this template

1. `rg -l 'rust[-_]cli[-_]template' | xargs sed -i 's/rust-cli-template/NAME/g; s/rust_cli_template/NAME_UNDERSCORED/g'`
2. Set `description` in `flake.nix`, `Cargo.toml` and `nix/package.nix`.
3. `nix develop -c cargo generate-lockfile && git add -A && nix flake check`
4. GitHub: Settings → Actions → allow GitHub Actions to create pull
   requests (the weekly flake-lock update needs it).
5. Replace `greet` with real commands, and delete this section.
