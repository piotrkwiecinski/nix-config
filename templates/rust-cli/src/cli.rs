//! The command line, declared with clap's derive API.
//!
//! Doc comments on the types and fields below are what `--help` prints, so
//! they are written for the person at the terminal, not for rustdoc readers.

use clap::{Parser, Subcommand};

/// A Rust command-line tool.
#[derive(Debug, Parser)]
#[command(version, about)]
pub struct Cli {
    /// What to do.
    #[command(subcommand)]
    pub command: Command,
}

/// The subcommands.
#[derive(Debug, Subcommand)]
pub enum Command {
    /// Print a greeting.
    Greet {
        /// Who to greet.
        name: String,
        /// Greet in capitals.
        #[arg(long)]
        shout: bool,
    },
}

#[cfg(test)]
mod tests {
    use clap::CommandFactory;

    use super::*;

    /// clap's own consistency checks: conflicting flags, bad defaults, ...
    #[test]
    fn command_definition_is_valid() {
        Cli::command().debug_assert();
    }

    #[test]
    fn parses_greet_with_shout() {
        let cli = Cli::try_parse_from(["rust-cli-template", "greet", "Ann", "--shout"]).unwrap();
        let Command::Greet { name, shout } = cli.command;
        assert_eq!(name, "Ann");
        assert!(shout);
    }
}
