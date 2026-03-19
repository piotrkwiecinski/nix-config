{
  pkgs,
  inputs,
  lib,
  ...
}:
let
  flakeDir = "/home/piotr/projects/nix-config";

  updateClaudeCodeScript = pkgs.writeShellScript "update-claude-code-flake" ''
    set -euo pipefail

    cd ${lib.escapeShellArg flakeDir}

    cp flake.lock flake.lock.bak
    trap '[ -f flake.lock.bak ] && mv flake.lock.bak flake.lock' ERR

    nix flake update claude-code-overlay magento-overlay opencode-nix codex-overlay

    if git diff --quiet flake.lock; then
      rm flake.lock.bak
      echo "No flake.lock changes, nothing to do."
      exit 0
    fi

    if sudo nixos-rebuild build --flake ".#thinkpad-x1-g3"; then
      sudo nixos-rebuild switch --flake ".#thinkpad-x1-g3"
      git add flake.lock
      git commit -m "flake: auto-update claude-code-overlay, magento-overlay, opencode-nix, and codex-overlay"
      git push
      rm flake.lock.bak
    else
      echo "Build failed, rolling back flake.lock"
      mv flake.lock.bak flake.lock
      exit 1
    fi
  '';
in
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

  xdg.mime.enable = true;

  programs.obs-studio = {
    enable = true;
    package = (
      pkgs.obs-studio.override {
        cudaSupport = true;
      }
    );
    plugins = with pkgs.unstable.obs-studio-plugins; [
      wlrobs
      obs-pipewire-audio-capture
    ];
  };

  fonts.fontconfig.enable = true;

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

  # opencode local model provider via Ollama.
  # Models: qwen3:4b-32k (fast, tools, 32k ctx), translategemma:4b (translation),
  # deepseek-r1:7b (reasoning, CPU+RAM). Use /models in opencode to switch.
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    mcp = {
      pantry = {
        type = "local";
        command = [ "/home/piotr/projects/pantry-app-v2/db/pantry-mcp-run.sh" ];
      };
      translate = {
        type = "local";
        command = [
          "node"
          "/home/piotr/.local/share/mcp-translate/index.mjs"
        ];
        environment = {
          OLLAMA_HOST = "http://localhost:11434";
          OLLAMA_MODEL = "gemma3:4b";
        };
      };
    };
    provider.ollama = {
      npm = "@ai-sdk/openai-compatible";
      name = "Ollama (local)";
      options = {
        baseURL = "http://localhost:11434/v1";
        apiKey = "{file:~/.config/ollama/api-key}";
      };
      models = {
        "qwen3:4b-32k" = {
          name = "Qwen3 4B (GPU, 32k tools)";
          tools = true;
          reasoning = true;
          limit = {
            context = 32768;
            output = 8192;
          };
        };
        "translategemma:4b" = {
          name = "TranslateGemma 4B (GPU, EN/IT/PL/JA)";
          limit = {
            context = 128000;
            output = 8192;
          };
        };
        "llama3.2:3b" = {
          name = "Llama 3.2 3B (GPU, tools)";
          tools = true;
          limit = {
            context = 32768;
            output = 8192;
          };
        };
        "mistral:7b" = {
          name = "Mistral 7B (GPU, tools)";
          tools = true;
          limit = {
            context = 4096;
            output = 4096;
          };
        };
        "deepseek-r1:7b" = {
          name = "DeepSeek R1 7B (CPU, reasoning)";
          limit = {
            context = 131072;
            output = 16384;
          };
        };
      };
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
      sox
      magento-cache-clean
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
      bun
      calibre
      ghostty
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
    inherit (pkgs) claude-code codex;
    inherit (pkgs.unstable) mochi;
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;

    # Source the sops-rendered Ollama env file in login shells (terminals,
    # SSH sessions).  Graphical apps get OLLAMA_API_KEY via the
    # ollama-env systemd user service instead.
    profileExtra = ''
      if [ -f "$HOME/.config/ollama/env" ]; then
        . "$HOME/.config/ollama/env"
        export OLLAMA_API_KEY
      fi
    '';

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

  systemd.user.services.update-claude-code-flake = {
    Unit = {
      Description = "Auto-update claude-code-overlay, magento-overlay, opencode-nix, and codex-overlay flake inputs";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${updateClaudeCodeScript}";
      Environment = "PATH=${
        lib.makeBinPath [
          pkgs.nix
          pkgs.git
        ]
      }:/run/wrappers/bin:/run/current-system/sw/bin";
    };
  };

  systemd.user.timers.update-claude-code-flake = {
    Unit.Description = "Timer for claude-code-overlay, magento-overlay, opencode-nix, and codex-overlay update";
    Timer = {
      OnCalendar = [
        "*-*-* 08:00:00"
        "*-*-* 12:00:00"
        "*-*-* 16:00:00"
        "*-*-* 20:00:00"
      ];
      Persistent = false;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # Italian vocabulary learning system
  systemd.user.services.learning-italian = {
    Unit = {
      Description = "Italian vocabulary learning server";
    };
    Service = {
      Type = "simple";
      WorkingDirectory = "/home/piotr/projects/learning-italian";
      ExecStart = "${pkgs.bun}/bin/bun run src/server.ts";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.italian-notify = {
    Unit = {
      Description = "Check for due Italian vocabulary reviews";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "/home/piotr/projects/learning-italian/scripts/notify-due.sh";
      Environment = "PATH=${
        lib.makeBinPath [
          pkgs.curl
          pkgs.jq
          pkgs.libnotify
        ]
      }:/run/wrappers/bin:/run/current-system/sw/bin";
    };
  };

  systemd.user.timers.italian-notify = {
    Unit.Description = "Timer for Italian vocabulary review notifications";
    Timer = {
      OnCalendar = "*:0/15";
      Persistent = false;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
