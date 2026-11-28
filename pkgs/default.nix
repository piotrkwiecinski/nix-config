{ pkgs, pkgs-unstable }:
rec {
  claude-code-ide = pkgs-unstable.emacsPackages.melpaBuild {
    pname = "claude-code-ide";
    version = "0.3.0-unstable-2026-11-20";
    src = pkgs.fetchFromGitHub {
      owner = "manzaltu";
      repo = "claude-code-ide.el";
      rev = "3e742ae7da47ef61091cc45d0f9e11172c376431";
      hash = "sha256-Rp5AeVdI+oV5FFDAaGk9a3WUX1PU4TlfGRtBv7kHaTw=";
    };
    packageRequires = with pkgs-unstable.emacsPackages; [
      vterm
      websocket
      transient
      web-server
    ];
    meta.homepage = "https://github.com/manzaltu/claude-code-ide.el";
  };

  claude-code-ide-companion = pkgs-unstable.emacsPackages.melpaBuild {
    pname = "claude-code-ide-companion";
    version = "0.1.0-unstable-2026-11-28";
    src = pkgs.fetchFromGitHub {
      owner = "piotrkwiecinski";
      repo = "claude-code-ide-companion.el";
      rev = "1124feea4f4a3c5fc4512f6735fb774c6cd48eba";
      hash = "sha256-8vhb/4fEAh18VcHqWTQhR18nZRmHOXbV5buNWRoBkxg=";
    };
    packageRequires = [ claude-code-ide ];
    meta.homepage = "https://github.com/piotrkwiecinski/claude-code-ide-companion.el";
  };

}
