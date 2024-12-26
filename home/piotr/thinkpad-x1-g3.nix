{ pkgs, inputs, ... }:
{
  imports = [
    ./global
    ./features/emacs
    ./features/direnv.nix
    ./features/desktop/common/firefox.nix
    (inputs.private-nix-config + "/home/piotr/work.nix")
  ];

  nix = {
    settings = {
      allowed-users = [ "@sudo" ];
      trusted-users = [
        "root"
        "@sudo"
      ];
    };
  };

  fonts.fontconfig.enable = true;

  services.polybar = {
    enable = true;
    script = ''
      for m in $(polybar --list-monitors | cut -d":" -f1); do
      MONITOR=$m polybar --reload main &
      done
    '';

    package = pkgs.unstable.polybar.override { pulseSupport = true; };
  };

  home.packages = with pkgs; [
    audacity
    fira-code
    fira-code-symbols
    fira-code-nerdfont
    unstable.gimp
    git
    htop
    unstable.jetbrains.idea-ultimate
    jq
    unstable.nil
    unstable.nixfmt-classic
    pavucontrol
    unstable.signal-desktop
    unstable.slack
    unstable.spotify
    yt-dlp
    unstable.devenv
    openvpn
    nodePackages.typescript-language-server
  ];

  programs.emacs.package = pkgs.emacs29;

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

  programs.feh.enable = true;

  services.picom = {
    enable = true;
    package = pkgs.unstable.picom;
    backend = "xrender";

    shadow = true;
    shadowExclude = [
      "name = 'Notification'"
      "class_g ?= 'Notify-osd'"
      "_GTK_FRAME_EXTENTS@:c"
    ];
    shadowOpacity = 0.5;

    settings = {
      shadow-color = "#0A0A0A";
      shadow-offset-x = -8;
      shadow-offset-y = -8;
      mark-wmwin-focused = true;
      detect-transient = true;
    };

    wintypes = {
      tooltip = {
        fade = true;
        shadow = true;
        opacity = 0.95;
        focus = true;
        full-shadow = false;
      };
      dock = {
        shadow = false;
        clip-shadow-above = true;
      };
      dnd = {
        shadow = false;
      };
      popup_menu = {
        opacity = 0.95;
      };
      dropdown_menu = {
        opacity = 0.95;
      };
    };
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
