{
  config,
  pkgs,
  inputs,
  outputs,
  lib,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./disk-config.nix
    inputs.home-manager.nixosModules.home-manager
    inputs.hardware.nixosModules.lenovo-thinkpad-x1-extreme-gen3
    ./hardware-configuration.nix
    ../../users/piotr
    inputs.private-nix-config.nixosModules.sops
    inputs.private-nix-config.nixosModules.secrets
    inputs.private-nix-config.nixosModules.thinkpad-x1-g3-secrets
    inputs.private-nix-config.nixosModules.thinkpad-x1-g3
  ];

  services.udev.packages = [
    pkgs.yubikey-personalization
    pkgs.libfido2
  ];

  services.pcscd.enable = true;

  security.pam.yubico = {
    enable = true;
    mode = "challenge-response";
    # Note: YubiKey ID cannot be moved to sops because it's needed at Nix evaluation time
    # for PAM configuration. sops secrets are only available at activation time.
    id = [ "32878882" ];
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    overlays = [
      inputs.emacs-overlay.overlays.default
      outputs.overlays.default
    ];
  };

  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = { inherit inputs outputs; };

  boot.kernelPackages = pkgs.linuxPackages_6_18;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.binfmt.registrations.aarch64-linux.fixBinary = true;

  boot.kernelParams = [
    "nvidia_drm.modeset=1"
    "nvidia_drm.fbdev=1"
    "i915.enable_psr=0" # Prevents flickering on ThinkPad X1
    "i915.enable_fbc=1" # Framebuffer compression for power saving
    "quiet"
    "loglevel=3"
    "systemd.show_status=auto"
    "rd.udev.log_level=3"
  ];

  # NVIDIA modules load during normal boot (not initrd) -- Intel iGPU
  # drives the display in PRIME offload mode, so early KMS is unnecessary.
  # Note: Do not use mkForce here as disko needs to add btrfs module for root mount.
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  boot.consoleLogLevel = 0;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 3;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 10;
  };

  services.irqbalance.enable = true;

  services.power-profiles-daemon.enable = false;

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 30;
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";
      START_CHARGE_THRESH_BAT0 = 20;
      STOP_CHARGE_THRESH_BAT0 = 80;
      SATA_LINKPWR_ON_AC = "med_power_with_dipm";
      SATA_LINKPWR_ON_BAT = "med_power_with_dipm";
      USB_AUTOSUSPEND = 1;
    };
  };

  services.thermald.enable = true;

  services.fwupd.enable = true;

  networking.hostName = "thinkpad-x1-g3";
  networking.hosts."192.168.68.106" = [ "homeserver" ];

  nix = {
    settings = {
      auto-optimise-store = true;
      max-jobs = 4;
      cores = 4;
      max-substitution-jobs = 32;
      http-connections = 50;
      connect-timeout = 5;
      stalled-download-timeout = 15;
      download-attempts = 3;
      narinfo-cache-negative-ttl = 300;
      extra-substituters = [
        "https://nix-community.cachix.org?priority=41"
        "https://emacs-ci.cachix.org?priority=42"
        "https://devenv.cachix.org?priority=43"
      ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "emacs-ci.cachix.org-1:B5FVOrxhXXrOL0S+tQ7USrhjMT5iOPH+QN9q0NItom4="
      ];
      flake-registry = "";
      keep-outputs = true;
      keep-derivations = true;
      experimental-features = "nix-command flakes";
    };
    daemonCPUSchedPolicy = "batch";
    daemonIOSchedClass = "best-effort";
    daemonIOSchedPriority = 4;
    channel.enable = false;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    registry.nixpkgs.flake = inputs.nixpkgs;
  };

  systemd.services.NetworkManager-wait-online.enable = false;

  # Enable networking
  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; [
      networkmanager-openvpn
    ];
  };

  networking.firewall = {
    allowedTCPPorts = [
      3000
      9001
      9003
      9090
      9000
      8123
      8282
    ];
  };

  # Set your time zone.
  time.timeZone = "Europe/Rome";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "it_IT.UTF-8";
    LC_IDENTIFICATION = "it_IT.UTF-8";
    LC_MEASUREMENT = "it_IT.UTF-8";
    LC_MONETARY = "it_IT.UTF-8";
    LC_NAME = "it_IT.UTF-8";
    LC_NUMERIC = "it_IT.UTF-8";
    LC_PAPER = "it_IT.UTF-8";
    LC_TELEPHONE = "it_IT.UTF-8";
    LC_TIME = "it_IT.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.desktopManager.cosmic.enable = true;
  environment.gnome.excludePackages = builtins.attrValues {
    inherit (pkgs)
      epiphany
      gnome-logs
      gnome-weather
      totem
      ;
  };

  services.displayManager.autoLogin = {
    enable = false;
    user = "piotr";
  };

  services.gnome.localsearch.enable = false;
  services.gnome.tinysparql.enable = false;
  services.gnome.gnome-browser-connector.enable = false;
  services.gnome.gnome-initial-setup.enable = false;
  services.gnome.gnome-remote-desktop.enable = false;
  services.gnome.rygel.enable = false;
  services.gnome.gnome-user-share.enable = false;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "gb";
    variant = "colemak";
  };

  # Configure console keymap
  console.keyMap = "uk";

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.browsed.enable = false;

  services.dnsmasq = {
    enable = true;
    alwaysKeepRunning = true;
    settings = {
      interface = [
        "wlp0s20f3"
        "docker0"
      ];
      bind-dynamic = true;
      address = [
        "/test/127.0.0.1"
        "/loc/127.0.0.1"
      ];
    };
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  hardware.nvidia = {
    open = false;
    nvidiaPersistenced = false; # Disabled: allows GPU D3 sleep with finegrained PM

    powerManagement = {
      enable = true;
      finegrained = true;
    };

    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
    };
  };
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 256;
        "default.clock.min-quantum" = 64;
        "default.clock.max-quantum" = 1024;
      };
    };

    extraConfig.pipewire-pulse."92-low-latency" = {
      "pulse.properties" = {
        "pulse.min.req" = "64/48000";
        "pulse.default.req" = "256/48000";
        "pulse.max.req" = "1024/48000";
        "pulse.min.quantum" = "64/48000";
        "pulse.max.quantum" = "1024/48000";
      };
    };

    wireplumber.extraConfig."99-disable-suspend" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            { "node.name" = "~alsa_output.*"; }
          ];
          actions = {
            update-props = {
              "session.suspend-timeout-seconds" = 0;
            };
          };
        }
        {
          matches = [
            { "node.name" = "~alsa_input.*"; }
          ];
          actions = {
            update-props = {
              "session.suspend-timeout-seconds" = 0;
            };
          };
        }
      ];
    };
  };

  hardware.graphics = {
    enable = true;

    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      nvidia-vaapi-driver
      vulkan-validation-layers
    ];
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-cosmic
    ];
  };

  environment.sessionVariables = {
    NVD_BACKEND = "direct";
  };

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs) gnome-tweaks tmux;
    inherit (pkgs.unstable)
      libnotify
      yubioath-flutter
      ;
    inherit (pkgs.master) opencode;
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
  };
  users.extraGroups.docker.members = [ "piotr" ];

  # Local LLM inference via Ollama with NVIDIA CUDA acceleration.
  # PRIME offload env vars are required because the Ollama systemd service
  # doesn't automatically use the dGPU (unlike user-session apps).
  # OLLAMA_API_KEY is injected via a sops-rendered EnvironmentFile so the
  # secret never appears as plaintext in the Nix store.
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    loadModels = [
      "qwen2.5:3b" # 1.9 GB — fits in 4 GB VRAM; fast general coding/chat
      "translategemma:4b" # 3.3 GB — fits in 4 GB VRAM; EN/IT/PL/JA + 52 other languages
      "deepseek-r1:7b" # 4.7 GB — CPU+RAM; reasoning and research tasks
    ];
    environmentVariables = {
      __NV_PRIME_RENDER_OFFLOAD = "1";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      CUDA_VISIBLE_DEVICES = "0";
    };
  };

  systemd.services.ollama.serviceConfig.EnvironmentFile =
    config.sops.templates."ollama-env".path;

  services.traefik = {
    enable = true;
    group = "docker";

    staticConfigFile = (pkgs.formats.toml { }).generate "traefik-static.toml" {
      api = {
        insecure = true;
        dashboard = true;
      };
      entryPoints = {
        web = {
          address = ":80";
          reusePort = true;
        };
        websecure = {
          address = ":443";
          reusePort = true;
        };
      };
      providers.docker = {
        watch = true;
        network = "local-dev-proxy";
        exposedByDefault = false;
      };
      providers.file = {
        directory = "/home/piotr/.config/traefik/dynamic";
        watch = true;
      };
      log.level = "info";
      global = {
        checkNewVersion = false;
        sendAnonymousUsage = false;
      };
      serversTransport.insecureSkipVerify = true;
      accessLog.filePath = "/var/lib/traefik/access.log";
    };
  };

  systemd.services.docker-network-local-dev-proxy = {
    description = "Create local-dev-proxy Docker network";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = lib.mkForce [ "docker.service" ];
    path = [ pkgs.docker ];
    script = ''
      docker network inspect local-dev-proxy >/dev/null 2>&1 || docker network create local-dev-proxy
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  systemd.services.traefik = {
    after = [
      "docker.service"
      "docker-network-local-dev-proxy.service"
    ];
    requires = [ "docker.service" ];
    wants = [ "docker-network-local-dev-proxy.service" ];
    serviceConfig = {
      ProtectHome = lib.mkForce "tmpfs";
      BindReadOnlyPaths = [ "/home/piotr/.config/traefik/dynamic" ];
    };
  };

  programs.firefox.enable = true;

  programs.gnupg = {
    package = pkgs.gnupg.override {
      pcsclite = pkgs.pcsclite;
    };
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-curses;
    enableExtraSocket = true;
  };

  systemd.timers."poweroff" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 23:50:00";
      Persistent = true;
    };
  };

  systemd.services."poweroff" = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/systemctl poweroff";
    };
    unitConfig = {
      Description = "Scheduled Poweroff";
    };
  };

  users.users."piotr" = {
    hashedPasswordFile = config.sops.secrets."piotr-password-hash".path;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1AkWOqdmzCuLtD1hbJHNbli12oqco1Zh8BHf1tif7zFAz6sNgkFGSp4+gySMIBv+Qk2SbNpGCI1XL2kpgTFUu2LbF3tfOjdP5uXGZfb1Af+rv/ESprBJjjiM8YuvD1TZ4Q25ie1eIyjcey30JJReA4K9nvHPr/nthpch7xfgnoO7Pkyf1OlEeZbp1Luo1s8mqb+oFYW9mcIfDzn5R7YvPshfflMQMXfbgXQ4usKpLNNrr5NjKpBETu9/wf/T9OUD/+2BFyiMrRZkJWtM3QCoXEYDWqcW0qvc4uSXMUyCYbHNtrxuhU1VIbDXDx2Gmkcs58NPnpxw9ONdkA5XS2pfEihElYNc8jF7uh24mjs1MICFZqFgsWWz6S9bYkqW1y/MDuhKy8IA2vdHiSFxVZbSFv6jf8LMQXDbxIHNhGoF8wTJCK/zNRtmOmSQnzi1DQcncYxy0WqoHTlR/beiPqtyaUNSEEyapr9vwagePvuY/4BKMTpamfEe/nGADJpBfcvs= piotr@piotr-laptop"
    ];
  };

  # SSH for remote nix builds from homeserver
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Builder user for remote nix builds from homeserver
  users.users.builder = {
    isNormalUser = true;
    description = "Nix remote builder";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMB6N/SY2fb+OqMYrB1P24ac44V1D/qMHTQ+4oZizPiw piotr@thinkpad-x1-g3"
    ];
  };

  nix.settings.trusted-users = [
    "root"
    "piotr"
    "builder"
  ];

  systemd.tmpfiles.rules =
    let
      traefikTlsConfig = pkgs.writeText "traefik-tls.toml" ''
        [[tls.certificates]]
        certFile = "${config.sops.secrets."traefik-cert".path}"
        keyFile = "${config.sops.secrets."traefik-key".path}"

        [tls.stores.default.defaultCertificate]
        certFile = "${config.sops.secrets."traefik-cert".path}"
        keyFile = "${config.sops.secrets."traefik-key".path}"
      '';
    in
    [
      "d /data/backups/paperless 0755 builder users -"
      "d /home/piotr/.config/traefik 0755 piotr users -"
      "d /home/piotr/.config/traefik/dynamic 0755 piotr users -"
      "L+ /home/piotr/.config/traefik/dynamic/tls.toml - - - - ${traefikTlsConfig}"
    ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
