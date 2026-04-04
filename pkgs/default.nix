{ pkgs, pkgs-unstable }:
rec {
  emacs-libgterm = pkgs-unstable.callPackage ./emacs-libgterm {
    emacs = pkgs-unstable.emacs30-pgtk;
  };
  claude-code-ide = pkgs-unstable.emacsPackages.trivialBuild {
    pname = "claude-code-ide";
    version = "0.2.7-unstable-2026-04-02";
    src = pkgs.fetchFromGitHub {
      owner = "manzaltu";
      repo = "claude-code-ide.el";
      rev = "56db02ee386d009ddb8b1482310f1f9beeefb810";
      hash = "sha256-qH1QnG5G+0UiH/v0KaS7oSpQZY+BkUMZvrjbx6kyFhg=";
    };
    patches = [
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
