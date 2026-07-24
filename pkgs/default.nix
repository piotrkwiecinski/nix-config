{ pkgs, pkgs-unstable }:
rec {
  claude-code-ide = pkgs-unstable.emacsPackages.trivialBuild {
    pname = "claude-code-ide";
    version = "0.2.7-unstable-2026-07-02";
    src = pkgs.fetchFromGitHub {
      owner = "manzaltu";
      repo = "claude-code-ide.el";
      rev = "cc508396a09e98931bb588da8542b73fa07733e2";
      hash = "sha256-pL5PNnemuXHHhQ0wEqhoagyKNdx+ywb2EEru8XWJ0Lc=";
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
