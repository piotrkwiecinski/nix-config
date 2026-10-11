//! `rust-cli-template`: a starting point for a Rust command-line tool.
//!
//! The binary in `src/main.rs` only forwards its arguments to [`run`]. The
//! crate is split by concern:
//!
//! - [`cli`] declares the command line with clap's derive API; its doc
//!   comments double as the `--help` text.
//! - [`greet`] is the example command's logic, free of I/O.
//! - [`error`] is the one error type every command returns.
//!
//! # Examples
//!
//! The command logic is plain functions, callable without a process:
//!
//! ```
//! use rust_cli_template::greet::greeting;
//!
//! assert_eq!(greeting("World", false)?, "Hello, World!");
//! # Ok::<(), rust_cli_template::Error>(())
//! ```

pub mod cli;
pub mod error;
pub mod greet;

use std::ffi::OsString;
use std::io::Write;
use std::process::ExitCode;

use clap::Parser;

use cli::{Cli, Command};
pub use error::Error;

/// The program name every diagnostic on stderr starts with.
pub const NAME: &str = env!("CARGO_PKG_NAME");

/// Run the CLI on `args` and return the process exit code.
///
/// `args` includes the program name, as [`std::env::args_os`] yields it.
/// Exit codes:
///
/// - `0` on success, and for `--help` / `--version`;
/// - `1` when a command fails, after printing `rust-cli-template: <error>`
///   on stderr;
/// - `2` on a usage error, after clap prints the error and usage on stderr.
///
/// # Examples
///
/// ```
/// use std::process::ExitCode;
///
/// let ok = rust_cli_template::run(["rust-cli-template", "greet", "World"]);
/// assert_eq!(ok, ExitCode::SUCCESS);
///
/// let usage = rust_cli_template::run(["rust-cli-template", "frobnicate"]);
/// assert_eq!(usage, ExitCode::from(2));
/// ```
pub fn run<I, T>(args: I) -> ExitCode
where
    I: IntoIterator<Item = T>,
    T: Into<OsString> + Clone,
{
    let cli = match Cli::try_parse_from(args) {
        Ok(cli) => cli,
        Err(err) => {
            // Help and version go to stdout with code 0, usage errors to
            // stderr with code 2; clap knows which is which. Nowhere to
            // report a failure to print either.
            let _ = err.print();
            return ExitCode::from(u8::try_from(err.exit_code()).unwrap_or(2));
        }
    };
    match dispatch(cli.command) {
        Ok(()) => ExitCode::SUCCESS,
        Err(err) => {
            let _ = writeln!(std::io::stderr().lock(), "{NAME}: {err}");
            ExitCode::FAILURE
        }
    }
}

/// Run one parsed `command`, writing its output to stdout.
///
/// # Errors
///
/// Whatever the command fails with, or [`Error::Io`] when stdout cannot be
/// written (a closed pipe, a full disk).
fn dispatch(command: Command) -> Result<(), Error> {
    let mut out = std::io::stdout().lock();
    match command {
        Command::Greet { name, shout } => writeln!(out, "{}", greet::greeting(&name, shout)?)?,
    }
    Ok(())
}
