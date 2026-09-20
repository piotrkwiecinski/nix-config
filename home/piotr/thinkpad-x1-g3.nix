{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
let
  flakeDir = "/home/piotr/projects/personal/nix-config";

  # Preflight shared by both auto-update services. Bails out (exit 0, so the
  # unit is not marked failed) when it is unsafe to run:
  #
  #   * another auto-update run is already in flight -- the two timers can
  #     otherwise overlap and deadlock each other on the nix store lock;
  #   * a nixos-rebuild is already running, whether ours or a manual one;
  #   * the working tree has uncommitted changes to tracked files. These would
  #     be activated by `nixos-rebuild switch` (flakes build from the working
  #     tree) and swept into the automation's own commit.
  autoUpdatePreflight = ''
    exec 9>"''${XDG_RUNTIME_DIR:-/tmp}/nix-config-auto-update.lock"
    if ! ${pkgs.util-linux}/bin/flock -n 9; then
      echo "Another auto-update run is in progress; skipping."
      exit 0
    fi

    # Matches both `nixos-rebuild switch ...` and the nixos-rebuild-ng
    # `.nixos-rebuild-wrapped switch ...` form. Requiring a subcommand keeps
    # unrelated command lines that merely mention the string from blocking us.
    if ${pkgs.procps}/bin/pgrep -f \
      'nixos-rebuild[^ ]* +(switch|build|boot|test|dry-activate|dry-build)' \
      >/dev/null 2>&1; then
      echo "A nixos-rebuild is already running; skipping."
      exit 0
    fi

    # `<4>` is the syslog warning prefix systemd strips and honours, so these
    # skips surface under `journalctl -p warning` rather than looking like
    # ordinary successful runs. This bail-out is the one failure mode with no
    # outward symptom: the unit exits 0 either way, so a tree left dirty by an
    # interrupted run silently parks the automation indefinitely.
    if ! git diff --quiet HEAD --; then
      echo "<4>Working tree has uncommitted changes; skipping to avoid"
      echo "<4>activating or committing manual edits."
      echo "<4>Nothing will auto-update until ${flakeDir} is clean."
      exit 0
    fi
  '';

  # Shared body for both auto-update services.
  #
  # `nixos-rebuild switch` activates home-manager, which restarts every user
  # unit whose definition changed -- and since flake.lock has just moved, that
  # includes the very unit running this script. systemd tears the old cgroup
  # down with SIGTERM, so nothing sequenced after the switch ever runs.
  #
  # That is exactly how the automation wedged itself on 2026-08-21: the switch
  # killed the run before `git commit`, flake.lock was left modified, and the
  # dirty-tree preflight then skipped every firing after it -- about fifty
  # consecutive no-ops, each exiting 0. Two properties keep it from recurring:
  #
  #   * commit and push as soon as `nixos-rebuild build` proves the new lock
  #     good, before switching. The build is the real gate; committing ahead of
  #     activation means being killed during it costs nothing, because the tree
  #     is already clean for the next run.
  #   * trap INT and TERM alongside ERR. The old trap fired only on ERR, which
  #     a SIGTERM is not, so a killed run orphaned flake.lock.bak and left the
  #     lock dirty rather than restoring it.
  mkAutoUpdateScript =
    {
      name,
      inputsToUpdate,
      commitMessage,
    }:
    pkgs.writeShellScript name ''
      set -euo pipefail

      cd ${lib.escapeShellArg flakeDir}

      ${autoUpdatePreflight}

      restoreLock() {
        if [ -f flake.lock.bak ]; then
          mv -f flake.lock.bak flake.lock
        fi
      }
      trap restoreLock ERR INT TERM

      cp flake.lock flake.lock.bak

      nix flake update ${lib.concatStringsSep " " inputsToUpdate}

      if git diff --quiet flake.lock; then
        rm -f flake.lock.bak
        echo "No flake.lock changes, nothing to do."
        exit 0
      fi

      if ! sudo nixos-rebuild build --flake ".#thinkpad-x1-g3"; then
        echo "Build failed, rolling back flake.lock"
        restoreLock
        exit 1
      fi

      git commit -m ${lib.escapeShellArg commitMessage} -- flake.lock
      git push
      rm -f flake.lock.bak
      # Past this point there is no backup to restore and the lock is safely
      # committed, so a SIGTERM from our own activation is harmless.
      trap - ERR INT TERM

      sudo nixos-rebuild switch --flake ".#thinkpad-x1-g3"
    '';

  updateClaudeCodeScript = mkAutoUpdateScript {
    name = "update-claude-code-flake";
    inputsToUpdate = [
      "claude-code-overlay"
      "magento-overlay"
      "opencode-nix"
      "codex-overlay"
    ];
    commitMessage = "flake: auto-update claude-code-overlay, magento-overlay, opencode-nix, and codex-overlay";
  };

  updateFlakeInputsScript = mkAutoUpdateScript {
    name = "update-flake-inputs";
    # nixpkgs-unstable-cuda is deliberately absent: services.ollama pulls
    # ollama-cuda from it, and bumping it can break the whole system build
    # with "CUDA Toolkit not found" in ggml-cuda.
    inputsToUpdate = [
      "nixpkgs"
      "nixpkgs-unstable"
      "nixpkgs-master"
      "flake-parts"
      "systems"
      "hardware"
      "home-manager"
      "emacs-overlay"
      "disko"
      "treefmt-nix"
      "private-nix-config"
    ];
    commitMessage = "chore: auto-update";
  };

  emacsclientFrameIfMissing = pkgs.writeShellScript "emacsclient-frame-if-missing" ''
    set -eu
    EMACSCLIENT="${config.programs.emacs.finalPackage}/bin/emacsclient"

    has_frame=$("$EMACSCLIENT" -e \
      '(if (seq-some (lambda (f) (and (frame-visible-p f) (display-graphic-p f))) (frame-list)) "yes" "no")' \
      2>/dev/null || echo '"no"')

    if [ "$has_frame" = '"yes"' ]; then
      exit 0
    fi

    exec "$EMACSCLIENT" -c -n
  '';

  # keyboxd -- spawned ad-hoc by gpg because ~/.gnupg/common.conf sets
  # `use-keyboxd`, and unlike gpg-agent it has no systemd unit of its own --
  # holds ~/.gnupg/public-keys.d/pubring.db.lock for its entire lifetime. When
  # the session is torn down at logout or suspend it gets killed without
  # releasing that lock, leaking one lock file per boot.
  #
  # A leaked lock is normally harmless: gpg reads the owning PID out of it and
  # breaks the lock once that process is gone. It turns fatal only when the PID
  # has since been reused by an unrelated long-lived process. gpg then sees a
  # live owner, waits, and every operation dies with
  # "keydb_search failed: Connection timed out". The Emacs daemon starts early
  # each boot and lands in the same low PID range keyboxd does, so the
  # collision is a question of when rather than if.
  #
  # Clear the locks at session start, but only when no keyboxd is actually
  # running, so a live lock is never yanked out from under one.
  gnupgStaleLockCleanup = pkgs.writeShellScript "gnupg-stale-lock-cleanup" ''
    set -eu
    GNUPGHOME="''${GNUPGHOME:-$HOME/.gnupg}"

    if ${pkgs.procps}/bin/pgrep -u "$(id -u)" -x keyboxd >/dev/null 2>&1; then
      echo "keyboxd is running; leaving its lock in place"
      exit 0
    fi

    rm -f "$GNUPGHOME/public-keys.d/pubring.db.lock"
    rm -f "$GNUPGHOME/public-keys.d/".#lk0x*
    rm -f "$GNUPGHOME/".#lk0x*
  '';
in
{
  imports = [
    inputs.private-nix-config.homeManagerModules.sops
    inputs.private-nix-config.homeManagerModules.sops-config
    inputs.private-nix-config.inputs.calstart.homeManagerModules.default
    inputs.private-nix-config.homeManagerModules.work
    inputs.private-nix-config.homeManagerModules.media
    inputs.private-nix-config.homeManagerModules.activitywatch-private
    inputs.private-nix-config.homeManagerModules.thinkpad-x1-g3
    ./global
    ./features/emacs
    ./features/direnv.nix
    ./features/desktop/common/firefox.nix
    ./features/desktop/activitywatch.nix
    ./features/mpv.nix
  ];

  home = {
    stateVersion = "26.05";
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
      pkgs.unstable-cuda.obs-studio.override {
        cudaSupport = true;
      }
    );
    plugins = with pkgs.unstable-cuda.obs-studio-plugins; [
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
        command = [ "/home/piotr/projects/opensource/pantry-app-v2/db/pantry-mcp-run.sh" ];
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
        "qwen2.5:3b" = {
          name = "Qwen 2.5 3B (GPU, tools, fast)";
          tools = true;
          limit = {
            context = 32768;
            output = 8192;
          };
        };
      };
    };
  };

  # Ordered ahead of gpg-agent so the first gpg operation of the session never
  # meets a leaked lock. See gnupgStaleLockCleanup above for the full story.
  systemd.user.services.gnupg-stale-lock-cleanup = {
    Unit = {
      Description = "Remove stale GnuPG keyboxd lock files";
      Before = [
        "gpg-agent.socket"
        "gpg-agent.service"
      ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${gnupgStaleLockCleanup}";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Open an Emacs frame on login, ordered after emacs.socket to avoid a race
  # where emacsclient fires before socket activation is ready and no frame
  # ever appears. The ExecStart guards against re-spawning a frame on rebuild:
  # home-manager restarts this unit whenever its content hash changes (which
  # happens whenever the emacs package store path moves), so a bare
  # `emacsclient -c -n` would create a duplicate frame on every rebuild.
  systemd.user.services.emacsclient-frame = {
    Unit = {
      Description = "Open an Emacs frame on login (idempotent)";
      After = [
        "emacs.socket"
        "graphical-session.target"
      ];
      Requires = [ "emacs.socket" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "forking";
      ExecStart = "${emacsclientFrameIfMissing}";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.packages = builtins.attrValues {
    inherit (pkgs)
      sox
      magento-cache-clean
      fira-code
      fira-code-symbols
      htop
      jq
      yq-go
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
      ispell
      libreoffice
      google-chrome
      open-in-mpv
      qpwgraph
      inkscape
      pipeline
      ripgrep
      forgejo-cli
      ;
    inherit (pkgs.master) pi-coding-agent;
    inherit (pkgs.unstable) davinci-resolve;
    inherit (pkgs.unstable.nerd-fonts) symbols-only;
    inherit (pkgs.unstable.jetbrains) idea;
    inherit (pkgs) typescript-language-server;
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

    # `settings` replaces the deprecated `matchBlocks` and takes upstream
    # ssh_config(5) directive names rather than camelCase aliases. The "*"
    # entry keeps its special meaning: home-manager always emits it last, so
    # first-match-wins still resolves per-host blocks before these defaults.
    settings = {
      "*" = {
        ServerAliveInterval = 300;
        ForwardAgent = true;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };

      "*.magento.cloud *.magentosite.cloud" = {
        Include = "~/.magento-cloud/ssh/*.config";
      };

      "homelab" = {
        HostName = "192.168.68.100";
        User = "piotr";
        IdentityFile = "~/.ssh/homelab";
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
      # Without this a hung rebuild lingers indefinitely, and the pgrep guard
      # would then make every later run skip.
      TimeoutStartSec = "1h";
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

  systemd.user.services.update-flake-inputs = {
    Unit = {
      Description = "Auto-update flake inputs (excluding CUDA and overlays)";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${updateFlakeInputsScript}";
      # Without this a hung rebuild lingers indefinitely, and the pgrep guard
      # would then make every later run skip.
      TimeoutStartSec = "1h";
      Environment = "PATH=${
        lib.makeBinPath [
          pkgs.nix
          pkgs.git
        ]
      }:/run/wrappers/bin:/run/current-system/sw/bin";
    };
  };

  systemd.user.timers.update-flake-inputs = {
    Unit.Description = "Timer for flake inputs update (excluding CUDA and overlays)";
    Timer = {
      OnCalendar = [
        "Fri,Sat,Sun *-*-* 09:00:00"
        "Fri,Sat,Sun *-*-* 17:00:00"
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
      WorkingDirectory = "/home/piotr/projects/personal/learning-italian";
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
      ExecStart = "/home/piotr/projects/personal/learning-italian/scripts/notify-due.sh";
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
