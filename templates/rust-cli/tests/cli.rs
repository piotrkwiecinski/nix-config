//! The binary end to end: arguments in, exit code and output out.
#![allow(
    clippy::unwrap_used,
    clippy::expect_used,
    clippy::panic,
    clippy::indexing_slicing,
    clippy::arithmetic_side_effects
)]

use std::process::{Command, Output};

/// A command for the binary under test, built by cargo for this test run.
fn bin() -> Command {
    Command::new(env!("CARGO_BIN_EXE_rust-cli-template"))
}

/// Run `cmd`; its exit code, stdout and stderr.
fn run(cmd: &mut Command) -> (Option<i32>, String, String) {
    let Output {
        status,
        stdout,
        stderr,
    } = cmd.output().unwrap();
    (
        status.code(),
        String::from_utf8(stdout).unwrap(),
        String::from_utf8(stderr).unwrap(),
    )
}

#[test]
fn greet_prints_the_greeting() {
    let (code, out, err) = run(bin().args(["greet", "World"]));
    assert_eq!(code, Some(0));
    assert_eq!(out, "Hello, World!\n");
    assert_eq!(err, "");
}

#[test]
fn greet_shout_uppercases() {
    let (code, out, _) = run(bin().args(["greet", "World", "--shout"]));
    assert_eq!(code, Some(0));
    assert_eq!(out, "HELLO, WORLD!\n");
}

#[test]
fn help_prints_usage_on_stdout() {
    let (code, out, err) = run(bin().arg("--help"));
    assert_eq!(code, Some(0));
    assert!(out.contains("Usage: rust-cli-template"), "{out}");
    assert_eq!(err, "");
}

#[test]
fn no_command_prints_usage_on_stderr_and_exits_2() {
    let (code, out, err) = run(&mut bin());
    assert_eq!(code, Some(2));
    assert_eq!(out, "");
    assert!(err.contains("Usage: rust-cli-template"), "{err}");
}

#[test]
fn command_failure_is_prefixed_and_exits_1() {
    let (code, out, err) = run(bin().args(["greet", " "]));
    assert_eq!(code, Some(1));
    assert_eq!(out, "");
    assert_eq!(err, "rust-cli-template: name must not be empty\n");
}
