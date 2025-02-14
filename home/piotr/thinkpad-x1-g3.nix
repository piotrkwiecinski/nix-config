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

  home.packages = with pkgs; [
    unstable.audacity
    fira-code
    fira-code-symbols
    fira-code-nerdfont
    unstable.nerd-fonts.symbols-only
    unstable.gimp
    git
    htop
    unstable.jetbrains.idea-ultimate
    jq
    unstable.nil
    unstable.slack
    unstable.spotify
    unstable.yt-dlp
    unstable.devenv
    openvpn
    nodePackages.typescript-language-server
    unstable.element-desktop
    unstable.maven
    unstable.jdk11
    montserrat
    unstable.nixVersions.latest
    unstable.nixpkgs-review
    unstable.gh
    unstable.lightningcss
    bc
    dig
    unstable.magento-cloud
    unstable.mpv
    unstable.ispell
  ];

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
      export NIX_PATH="$HOME/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels''${NIX_PATH:+:$NIX_PATH}";
      PATH="$HOME/.cargo/bin:$HOME/bin:$PATH"
      # BEGIN SNIPPET: Magento Cloud CLI configuration
      export PATH="$HOME/"'.magento-cloud/bin':"$PATH"
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
