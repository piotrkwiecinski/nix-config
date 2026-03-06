{ pkgs, pkgs-unstable }:
rec {
  claude-code-ide = pkgs-unstable.emacsPackages.trivialBuild {
    pname = "claude-code-ide";
    version = "0-unstable-2026-03-06";
    src = pkgs.fetchFromGitHub {
      owner = "manzaltu";
      repo = "claude-code-ide.el";
      rev = "5f12e60c6d2d1802c8c1b7944bbdf935d5db1364";
      hash = "sha256-tivRvgfI/8XBRImE3wuZ1UD0t2dNWYscv3Aa53BmHZE=";
    };
    packageRequires = with pkgs-unstable.emacsPackages; [
      vterm
      websocket
      transient
      web-server
    ];
    meta.homepage = "https://github.com/manzaltu/claude-code-ide.el";
  };

  claude-code-ide-extras = pkgs-unstable.emacsPackages.trivialBuild {
    pname = "claude-code-ide-extras";
    version = "0.1.0";
    src = pkgs.fetchFromGitHub {
      owner = "piotrkwiecinski";
      repo = "claude-code-ide-extras.el";
      rev = "e766e9c0082ebdff7343c008b75ce0f935541f49";
      hash = "sha256-TkphvvnOAaKtv/qpEKvQ51l1iZFZHG47wDdxfmwy/g8=";
    };
    packageRequires = [ claude-code-ide ];
    meta.homepage = "https://github.com/piotrkwiecinski/claude-code-ide-extras.el";
  };

}
