{ pkgs, pkgs-unstable }:
{
  claude-code-ide = pkgs-unstable.emacsPackages.trivialBuild {
    pname = "claude-code-ide";
    version = "0-unstable-2026-03-05";
    src = pkgs.fetchFromGitHub {
      owner = "piotrkwiecinski";
      repo = "claude-code-ide.el";
      rev = "cef22b3148e199a1f6e334d48848433ed4b9889b";
      hash = "sha256-6fmb5hSoyuzpDrMKZxVzgLNJ1IWCgKDD61A5qK8yX+U=";
    };
    patches = [
      (pkgs.fetchpatch {
        url = "https://github.com/manzaltu/claude-code-ide.el/commit/34fce7a4312ea6cb7824b89a7c789a3b942db958.patch";
        hash = "sha256-PSBrgsECPhvMDYYzdS7nRn9qaSe7OkuJm+3IIwXaE6Q=";
      })
      (pkgs.fetchpatch {
        url = "https://github.com/manzaltu/claude-code-ide.el/pull/158.patch";
        hash = "sha256-6k/vVxDcQxqN7zNWPMpObW9nPWVKZeGH+giCQnnbJew=";
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

  magento-cache-clean = pkgs.callPackage ./magento-cache-clean.nix { };
}
