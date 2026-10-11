//! The `rust-cli-template` binary.
//!
//! A thin shell over the library: everything worth testing lives in
//! [`rust_cli_template`], so unit tests and doctests reach it without
//! spawning a process.

use std::process::ExitCode;

/// Run the CLI on the process arguments and exit with its code.
fn main() -> ExitCode {
    rust_cli_template::run(std::env::args_os())
}
