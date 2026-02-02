{ pkgs, pkgs-unstable }:
{
  claude-code-ide = pkgs-unstable.emacsPackages.trivialBuild {
    pname = "claude-code-ide";
    version = "0-unstable-2026-02-01";
    src = pkgs.fetchFromGitHub {
      owner = "manzaltu";
      repo = "claude-code-ide.el";
      rev = "a5494523dc8c3031375aa53d6321abfd9bc7288b";
      hash = "sha256-Mw5MNx4RMk+2oXcjIVclel1jis1jHTj8S3uqTDYN4KQ=";
    };
    packageRequires = with pkgs-unstable.emacsPackages; [
      vterm
      websocket
      transient
      web-server
    ];
    meta.homepage = "https://github.com/manzaltu/claude-code-ide.el";
  };
}
