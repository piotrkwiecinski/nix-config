{
  inputs,
  outputs,
  pkgs,
  ...
}: {
  imports = [
    ./global
    ./features/emacs
    ./features/desktop/common/firefox.nix
  ];

  nixpkgs = {
    overlays = [
      outputs.overlays.unstable-packages
      inputs.emacs-overlay.overlays.default
    ];
  };

  home.packages = with pkgs; [
    nodejs_20
    htop
    signal-desktop
    fira-code
    fira-code-symbols
    fira-code-nerdfont
    jq
    spotify
  ];

  programs.bash = {
    enable = true;
    enableCompletion = true;
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
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };

  fonts.fontconfig.enable = true;
}
