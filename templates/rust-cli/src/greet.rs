//! The `greet` command: the example to replace with real work.
//!
//! Kept free of I/O so it is tested as plain functions; [`crate::run`]
//! prints the result.

use crate::Error;

/// The greeting for `name`, in capitals when `shout` is set.
///
/// Surrounding whitespace in `name` is dropped.
///
/// # Errors
///
/// [`Error::EmptyName`] when `name` is empty or only whitespace.
///
/// # Examples
///
/// ```
/// use rust_cli_template::greet::greeting;
///
/// assert_eq!(greeting("World", false)?, "Hello, World!");
/// assert_eq!(greeting(" World ", true)?, "HELLO, WORLD!");
/// assert!(greeting("  ", false).is_err());
/// # Ok::<(), rust_cli_template::Error>(())
/// ```
pub fn greeting(name: &str, shout: bool) -> Result<String, Error> {
    let name = name.trim();
    if name.is_empty() {
        return Err(Error::EmptyName);
    }
    let text = format!("Hello, {name}!");
    Ok(if shout { text.to_uppercase() } else { text })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn greets_by_name() {
        assert_eq!(greeting("Ann", false).unwrap(), "Hello, Ann!");
    }

    #[test]
    fn shouting_uppercases_the_whole_greeting() {
        assert_eq!(greeting("Ann", true).unwrap(), "HELLO, ANN!");
    }

    #[test]
    fn blank_name_is_an_error() {
        for name in ["", " ", "\t\n"] {
            assert!(
                matches!(greeting(name, false), Err(Error::EmptyName)),
                "{name:?}"
            );
        }
    }
}
