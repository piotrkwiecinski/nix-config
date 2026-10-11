{ ... }:
{
  flake.templates.rust-cli = {
    path = ../templates/rust-cli;
    description = "Rust CLI: clap, crane, flake-parts, strict clippy, GitHub CI";
    welcomeText = ''
      # Rust CLI

      Rename the `rust-cli-template` placeholder before anything else: the
      steps are under "Starting a project from this template" in AGENTS.md.
    '';
  };
}
