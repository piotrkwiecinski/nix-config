{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;
    userName = "Piotr Kwiecinski";
    userEmail = "piokwiecinski@gmail.com";
    lfs.enable = true;
    extraConfig = {
      init.defaultBranch = "main";
    };
    ignores = [
      ".direnv"
      "result"
      "*~"
      "*.swp"
      ".idea/"
      "node_modules/"
      "*.elc"
    ];
  };
}
