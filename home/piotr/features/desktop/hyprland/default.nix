# Hyprland session config; the compositor itself comes from the NixOS module
# (modules/nixos/features/hyprland.nix).
#
# Helpers never hang off graphical-session.target, which GNOME reaches too
# (mako would fight gnome-shell for the notification bus name, hypridle would
# lock the screen a second time): bar, notifications and polkit agent start
# from exec-once through `uwsm app`, hypridle from UWSM's Hyprland-only target.
{ pkgs, lib, ... }:
let
  app = cmd: "uwsm app -- ${cmd}";
  lock = "pidof hyprlock || hyprlock";
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    # UWSM owns the session and environment import.
    systemd.enable = false;

    settings = {
      "$mod" = "SUPER";
      "$terminal" = "ghostty";
      "$launcher" = "fuzzel";

      monitor = [ ",preferred,auto,auto" ];

      input = {
        kb_layout = "gb";
        kb_variant = "colemak";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
        };
      };

      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        layout = "dwindle";
      };

      decoration.rounding = 6;
      animations.enabled = false;

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };

      exec-once = [
        (app "waybar")
        (app "mako")
        (app "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent")
      ];

      bind = [
        "$mod, Return, exec, ${app "$terminal"}"
        "$mod, Space, exec, $launcher --launch-prefix='uwsm app -- '"
        "$mod, Q, killactive"
        "$mod SHIFT, E, exec, uwsm stop"
        "$mod, Escape, exec, loginctl lock-session"
        "$mod, F, fullscreen"
        "$mod, V, togglefloating"
        "$mod, P, pseudo"
        "$mod, J, togglesplit"

        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, down, movewindow, d"

        # Screenshots: region to clipboard, full screen to clipboard
        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
        "SHIFT, Print, exec, grim - | wl-copy"
      ]
      ++ lib.concatMap (
        n:
        let
          key = toString (lib.mod n 10);
        in
        [
          "$mod, ${key}, workspace, ${toString n}"
          "$mod SHIFT, ${key}, movetoworkspace, ${toString n}"
        ]
      ) (lib.range 1 10);

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];

      bindl = [
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ];
    };
  };

  # Read by UWSM only when it starts Hyprland, so GNOME never sees these.
  # Pin Aquamarine to the Intel iGPU (drives the panel in PRIME offload mode);
  # opening the NVIDIA card too would keep it out of D3 sleep. The by-path name
  # holds colons, which AQ_DRM_DEVICES uses as a separator, so resolve it.
  xdg.configFile."uwsm/env-hyprland".text = ''
    export AQ_DRM_DEVICES="$(readlink -f /dev/dri/by-path/pci-0000:00:02.0-card)"
  '';

  programs.waybar = {
    enable = true;
    settings.main = {
      layer = "top";
      position = "top";
      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [
        "pulseaudio"
        "network"
        "battery"
        "tray"
      ];
      clock.format = "{:%a %d %b  %H:%M}";
      battery.format = "{capacity}% {icon}";
      network = {
        format-wifi = "{essid}";
        format-disconnected = "offline";
      };
    };
  };

  programs.fuzzel.enable = true;

  services.mako = {
    enable = true;
    settings.default-timeout = 5000;
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      general.hide_cursor = true;
      background = [
        {
          color = "rgb(1e1e2e)";
        }
      ];
      input-field = [
        {
          size = "300, 50";
          position = "0, 0";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  services.hypridle = {
    enable = true;
    # UWSM's per-compositor target, never reached in a GNOME session.
    systemdTarget = "wayland-session@hyprland.desktop.target";
    settings = {
      general = {
        lock_cmd = lock;
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  home.packages = with pkgs; [
    brightnessctl
    grim
    slurp
    wl-clipboard
  ];
}
