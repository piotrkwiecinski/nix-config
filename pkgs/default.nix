{ pkgs, pkgs-unstable }:
rec {
  claude-code-ide = pkgs-unstable.emacsPackages.trivialBuild {
    pname = "claude-code-ide";
    version = "0.3.0";
    src = pkgs.fetchFromGitHub {
      owner = "manzaltu";
      repo = "claude-code-ide.el";
      rev = "89977293a0d822bc5ebd3257e6e3f5906d83e1be";
      hash = "sha256-ivznQRoKgMJ8riA745GzeT5CLBNMH45j1UnTWvU3OGI=";
    };
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
