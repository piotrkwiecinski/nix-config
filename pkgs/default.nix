{ pkgs, pkgs-unstable }:
{
  claude-code-ide = pkgs-unstable.emacsPackages.trivialBuild {
    pname = "claude-code-ide";
    version = "0-unstable-2026-03-06";
    src = pkgs.fetchFromGitHub {
      owner = "piotrkwiecinski";
      repo = "claude-code-ide.el";
      rev = "f52eb3ab76cb7d6b8d88a9db64cac3e9f8d40ce0";
      hash = "sha256-mNF+u332TgTwvBIZy/bhYWwR7byEYigssqnlJU3OpMI=";
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
    meta.homepage = "https://github.com/piotrkwiecinski/claude-code-ide.el";
  };

}
