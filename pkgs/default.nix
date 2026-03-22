{ pkgs, pkgs-unstable }:
rec {
  emacs-libgterm = pkgs-unstable.callPackage ./emacs-libgterm {
    emacs = pkgs-unstable.emacs30-pgtk;
  };
  claude-code-ide = pkgs-unstable.emacsPackages.trivialBuild {
    pname = "claude-code-ide";
    version = "0-unstable-2026-03-06";
    src = pkgs.fetchFromGitHub {
      owner = "manzaltu";
      repo = "claude-code-ide.el";
      rev = "5f12e60c6d2d1802c8c1b7944bbdf935d5db1364";
      hash = "sha256-tivRvgfI/8XBRImE3wuZ1UD0t2dNWYscv3Aa53BmHZE=";
    };
    patches = [
      (pkgs.fetchpatch {
        name = "anti-flicker-fixes.patch";
        url = "https://github.com/manzaltu/claude-code-ide.el/pull/158.patch";
        hash = "sha256-CLWld5QbZSGRX/0Ip8ZszeaNESaBRWtYSNVr30I0Wy0=";
      })
      (pkgs.fetchpatch {
        name = "fix-hl-line-range-function.patch";
        url = "https://github.com/manzaltu/claude-code-ide.el/pull/164.patch";
        hash = "sha256-PSBrgsECPhvMDYYzdS7nRn9qaSe7OkuJm+3IIwXaE6Q=";
      })
      (pkgs.fetchpatch {
        name = "fix-restore-buffer-read-only-after-ediff.patch";
        url = "https://github.com/manzaltu/claude-code-ide.el/pull/167.patch";
        hash = "sha256-s12dx6JUx2scZ/KHnBcf4KeggGsD179SS1oKVxI6MCk=";
      })
      (pkgs.fetchpatch {
        name = "add-gterm-backend.patch";
        url = "https://github.com/manzaltu/claude-code-ide.el/pull/178.patch";
        hash = "sha256-8tXp1a7zRUMaH7MotdEpm1/Q+zYVZKACZQguc7jhmTo=";
      })
    ];
    packageRequires = with pkgs-unstable.emacsPackages; [
      vterm
      websocket
      transient
      web-server
    ];
    meta.homepage = "https://github.com/manzaltu/claude-code-ide.el";
  };

  claude-code-ide-companion = pkgs-unstable.emacsPackages.trivialBuild {
    pname = "claude-code-ide-companion";
    version = "0.1.0";
    src = pkgs.fetchFromGitHub {
      owner = "piotrkwiecinski";
      repo = "claude-code-ide-companion.el";
      rev = "120445f0dc249e80fdf8be85f35b130655c917c0";
      hash = "sha256-tuRwdDtW8ctTSZyj7g7ohdhfJj0nfV8uFyPAHYzphqM=";
    };
    packageRequires = [ claude-code-ide ];
    meta.homepage = "https://github.com/piotrkwiecinski/claude-code-ide-companion.el";
  };

}
