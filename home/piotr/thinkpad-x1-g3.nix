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

  # Configure scdaemon to not hold exclusive access to YubiKey,
  # allowing FIDO2/WebAuthn to work alongside GPG smartcard
  programs.gpg.scdaemonSettings = {
    disable-ccid = true;
    card-timeout = 1;
  };

  programs.gh = {
    enable = true;
    package = pkgs.unstable.gh;
    settings = {
      git_protocol = "ssh";
    };
  };

  xdg.configFile."autostart/emacsclient.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Emacsclient
    Exec=emacsclient -c
    Icon=emacs
    Comment=Connect to Emacs daemon
    X-GNOME-Autostart-enabled=true
  '';

  home.packages = builtins.attrValues {
    calstart = inputs.calstart.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
      claude-code
      gimp3
      nil
      slack
      yt-dlp
      devenv
      element-desktop
      bruno
      maven
      jdk11
      nixpkgs-review
      magento-cloud
      mpv
      ispell
      libreoffice
      google-chrome
      open-in-mpv
      qpwgraph
      inkscape
      davinci-resolve
      pipeline
      ripgrep
      ;
    inherit (pkgs.unstable.nerd-fonts) symbols-only;
    inherit (pkgs.unstable.jetbrains) idea;
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
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        serverAliveInterval = 300;
        forwardAgent = true;
        addKeysToAgent = "no";
        compression = false;
        serverAliveCountMax = 3;
        hashKnownHosts =  false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };

      "*.magento.cloud *.magentosite.cloud" = {
        extraOptions = {
          Include = "~/.magento-cloud/ssh/*.config";
        };
      };

      "homelab" = {
        hostname = "192.168.68.100";
        user = "piotr";
        identityFile = "~/.ssh/homelab";
      };
    };
  };
}
