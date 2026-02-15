{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.private-nix-config.homeManagerModules.sops
    inputs.private-nix-config.homeManagerModules.sops-config
    inputs.private-nix-config.inputs.calstart.homeManagerModules.default
    inputs.private-nix-config.homeManagerModules.work
    ./global
    ./features/emacs
    ./features/direnv.nix
    ./features/desktop/common/firefox.nix
  ];

  home = {
    stateVersion = "25.11";
  };

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_DISABLE_RDD_SANDBOX = "1";
  };

  # Configure scdaemon to not hold exclusive access to YubiKey,
  # allowing FIDO2/WebAuthn to work alongside GPG smartcard
  programs.gpg.scdaemonSettings = {
    disable-ccid = true;
    card-timeout = 1;
  };

  # Required for KeePassXC autostart
  xdg.autostart.enable = true;

  # KeePassXC as secret service provider (replaces gnome-keyring for app secrets)
  # Supports YubiKey challenge-response for database unlock
  programs.keepassxc = {
    enable = true;
    autostart = true;
    settings = {
      General = {
        ConfigVersion = 2;
      };
      FdoSecrets = {
        Enabled = true;
      };
    };
  };

  # Disable gnome-keyring entirely - GPG agent handles SSH, KeePassXC handles secrets
  services.gnome-keyring.enable = false;

  dconf.settings = {
    "org/gnome/mutter" = {
      experimental-features = [
        "variable-refresh-rate"
      ];
    };

    "org/gnome/desktop/interface" = {
      enable-animations = false;
    };

    "org/gnome/software" = {
      download-updates = false;
      allow-updates = false;
    };

    "org/gnome/desktop/search-providers" = {
      disabled = [
        "org.gnome.Nautilus.desktop"
        "org.gnome.Calendar.desktop"
        "org.gnome.Contacts.desktop"
        "org.gnome.Characters.desktop"
        "org.gnome.clocks.desktop"
        "org.gnome.Software.desktop"
      ];
    };
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
    inherit (pkgs)
      dm
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
    inherit (pkgs.master) claude-code-bin mochi;
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      "bhc" = "bluetoothctl connect 00:16:94:22:81:6C";
      "c2" = "dm composer";
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
        hashKnownHosts = false;
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
