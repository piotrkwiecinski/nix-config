//! The crate's error type.
//!
//! One enum for every command, so [`crate::run`] has a single place that
//! turns failures into a message on stderr and exit code `1`. Its
//! [`Display`](std::fmt::Display) is that message, without the program-name
//! prefix.

use std::fmt;
use std::io;

/// Why a command failed.
#[derive(Debug)]
pub enum Error {
    /// The name to greet was empty or only whitespace.
    EmptyName,
    /// Writing the output failed.
    Io(io::Error),
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::EmptyName => f.write_str("name must not be empty"),
            Self::Io(err) => write!(f, "cannot write output: {err}"),
        }
    }
}

impl std::error::Error for Error {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::EmptyName => None,
            Self::Io(err) => Some(err),
        }
    }
}

impl From<io::Error> for Error {
    fn from(err: io::Error) -> Self {
        Self::Io(err)
    }
}
