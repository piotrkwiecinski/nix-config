{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./global
    ./features/emacs
    ./features/direnv.nix
    ./features/desktop/common/firefox.nix
    (inputs.private-nix-config + "/home/piotr/work.nix")
  ];

  home = {
    stateVersion = "24.11";
  };

  fonts.fontconfig.enable = true;

  home.packages = builtins.attrValues {
    inherit (pkgs)
      fira-code
      fira-code-symbols
      htop
      jq
      openvpn
      montserrat
      bc
      dig
      ;
    inherit (pkgs.unstable)
      audacity
      calibre
      gimp3
      nil
      slack
      spotify
      yt-dlp
      devenv
      element-desktop
      postman
      maven
      jdk11
      gh
      nixpkgs-review
      lightningcss
      magento-cloud
      mpv
      ispell
      libreoffice
      google-chrome
      open-in-mpv
      qpwgraph
      inkscape
      davinci-resolve
      ;
    inherit (pkgs.unstable.nerd-fonts) symbols-only;
    idea-ultimate = pkgs.unstable.jetbrains.idea-ultimate.override {
      jdk = pkgs.unstable.jdk;
    };
    inherit (pkgs.nodePackages) typescript-language-server;
    inherit (pkgs.unstable.nixVersions) latest;
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      "bhc" = "bluetoothctl connect 00:16:94:22:81:6C";
      "c2" = "dm composer";
      "dm" = "~/bin/dm";
      "m2" = "dm magento";
      "mr2" = "dm n98-magerun2";
      "ls" = "ls --color=auto";
      "la" = "ls -la";
      "ll" = "ls -l";
    };

    historyControl = [
      "erasedups"
      "ignoredups"
    ];
    historyIgnore = [ "exit" ];

    bashrcExtra = ''
      # BEGIN SNIPPET: Magento Cloud CLI configuration
      if [ -f "$HOME/"'.magento-cloud/shell-config.rc' ]; then . "$HOME/"'.magento-cloud/shell-config.rc'; fi
      # END SNIPPET
    '';
  };

  programs.ssh = {
    enable = true;

    serverAliveInterval = 300;
    serverAliveCountMax = 2;
    forwardAgent = true;

    extraConfig = ''
      # BEGIN: Magento Cloud certificate configuration
      Host *.magento.cloud *.magentosite.cloud
        Include ~/.magento-cloud/ssh/*.config
      Host *
      # END: Magento Cloud certificate configuration
    '';

    matchBlocks = {
      "homelab" = {
        hostname = "192.168.68.100";
        user = "piotr";
        identityFile = "~/.ssh/homelab";
      };
    };
  };
}
