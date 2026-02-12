{ pkgs, pkgs-unstable }:
{
  claude-code-ide = pkgs-unstable.emacsPackages.trivialBuild {
    pname = "claude-code-ide";
    version = "0-unstable-2026-02-02";
    src = pkgs.fetchFromGitHub {
      owner = "manzaltu";
      repo = "claude-code-ide.el";
      rev = "5f12e60c6d2d1802c8c1b7944bbdf935d5db1364";
      hash = "sha256-tivRvgfI/8XBRImE3wuZ1UD0t2dNWYscv3Aa53BmHZE=";
    };
    patches = [
      (pkgs.fetchpatch {
        url = "https://github.com/manzaltu/claude-code-ide.el/commit/34fce7a4312ea6cb7824b89a7c789a3b942db958.patch";
        hash = "sha256-PSBrgsECPhvMDYYzdS7nRn9qaSe7OkuJm+3IIwXaE6Q=";
      })
      (pkgs.fetchpatch {
        url = "https://github.com/manzaltu/claude-code-ide.el/commit/24d75f9b6e8a8a4ae2126b0f503d47b63b9592bd.patch";
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
}
