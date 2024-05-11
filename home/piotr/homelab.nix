{
  pkgs,
  ...
}: {
  imports = [./global];

  home.packages = [pkgs.emacs29 pkgs.htop];

  programs.firefox.enable = true;

  programs.bash = {
    enable = true;
  };

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
    ];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}