# Hyprland session config; the compositor itself comes from the NixOS module
# (modules/nixos/features/hyprland.nix).
#
# Helpers never hang off graphical-session.target, which GNOME reaches too
# (mako would fight gnome-shell for the notification bus name, hypridle would
# lock the screen a second time, hyprpaper would crash-loop without
# layer-shell): bar, wallpaper, notifications and polkit agent start from
# exec-once through `uwsm app`, hypridle from UWSM's Hyprland-only target.
#
# Look and keys follow the GNOME session: Adwaita dark with the slate accent,
# a black top bar with the clock in the middle, the same wallpaper, no
# animations, and GNOME's bindings where Hyprland has an equivalent.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  app = cmd: "uwsm app -- ${cmd}";
  lock = "pidof hyprlock || hyprlock";

  # The GNOME wallpaper (org.gnome.desktop.background picture-uri). Kept out of
  # the repo; both sessions read the same file.
  wallpaper = "${config.home.homeDirectory}/.config/background";

  # Adwaita dark palette and GNOME's "slate" accent.
  colors = {
    accent = "6f8396";
    bg = "222226";
    popup = "36363a";
    fg = "ffffff";
    dim = "c0bfbc";
  };
  font = "Adwaita Sans";
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    # stateVersion 26.05 defaults to Lua, but `settings` below is written in
    # hyprlang style ($mod, "mod, key, dispatcher" binds); rendered as Lua it
    # does not parse and Hyprland starts with none of it.
    configType = "hyprlang";
    # UWSM owns the session and environment import.
    systemd.enable = false;

    settings = {
      "$mod" = "SUPER";
      "$terminal" = "ghostty";
      "$launcher" = "fuzzel --launch-prefix='uwsm app -- '";

      monitor = [ ",preferred,auto,auto" ];

      input = {
        # GNOME input sources: gb+colemak first, plain gb second (Super+Space).
        kb_layout = "gb,gb";
        kb_variant = "colemak,";
        kb_options = "terminate:ctrl_alt_bksp,lv3:ralt_switch";
        # GNOME focus-mode 'click': hovering scrolls, clicking focuses.
        follow_mouse = 2;
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
          tap-and-drag = true;
          disable_while_typing = true;
          # click-method 'fingers'
          clickfinger_behavior = true;
        };
      };

      # GNOME's three-finger swipe between workspaces.
      gesture = [ "3, horizontal, workspace" ];

      # one-window-wonderland ran with gap-size=0 and undecorated windows, so
      # tiles meet edge to edge with only a thin accent line on the focused one.
      general = {
        gaps_in = 0;
        gaps_out = 0;
        border_size = 1;
        "col.active_border" = "rgb(${colors.accent})";
        "col.inactive_border" = "rgba(00000000)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 0;
        shadow.enabled = false;
        blur.enabled = false;
      };

      # org.gnome.desktop.interface enable-animations=false
      animations.enabled = false;

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        background_color = "rgb(000000)";
        focus_on_activate = true;
      };

      exec-once = [
        (app "hyprpaper")
        (app "waybar")
        (app "mako")
        (app "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent")
      ];

      # Tapping Super alone opens the launcher, like GNOME's overlay key.
      bindr = [ "$mod, SUPER_L, exec, $launcher" ];

      bind = [
        # GNOME custom keybinding and defaults
        "$mod, Return, exec, ${app "emacsclient -r -a ''"}"
        "CTRL ALT, T, exec, ${app "$terminal"}"
        "$mod, A, exec, $launcher"
        "$mod, Space, exec, hyprctl switchxkblayout all next"
        "$mod, C, exec, loginctl lock-session"
        "$mod, Q, killactive"
        "ALT, F4, killactive"
        "$mod SHIFT, E, exec, uwsm stop"

        # Window switching
        "ALT, Tab, cyclenext"
        "ALT, Tab, bringactivetotop"
        "ALT SHIFT, Tab, cyclenext, prev"
        "ALT SHIFT, Tab, bringactivetotop"
        "$mod, Tab, cyclenext"
        "$mod, Tab, bringactivetotop"

        # Super+Up maximises (tiling-assistant tile-maximize); F goes fullscreen.
        "$mod, Up, fullscreen, 1"
        "$mod, F, fullscreen"
        "$mod, V, togglefloating"
        "$mod, P, pseudo"
        "$mod, J, layoutmsg, togglesplit"

        # Super+Left/Right moved windows into halves under tiling-assistant;
        # moving the tile is the nearest match. Focus moves with Super+Alt.
        "$mod, Left, movewindow, l"
        "$mod, Right, movewindow, r"
        "$mod, Down, movewindow, d"
        "$mod ALT, left, movefocus, l"
        "$mod ALT, right, movefocus, r"
        "$mod ALT, up, movefocus, u"
        "$mod ALT, down, movefocus, d"

        # GNOME workspace navigation
        "$mod, Page_Up, workspace, e-1"
        "$mod, Page_Down, workspace, e+1"
        "$mod SHIFT, Page_Up, movetoworkspace, e-1"
        "$mod SHIFT, Page_Down, movetoworkspace, e+1"
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"

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
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPause, exec, playerctl pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
      ];
    };
  };

  # Read by UWSM only when it starts Hyprland, so GNOME never sees these.
  # Pin Aquamarine to the Intel iGPU (drives the panel in PRIME offload mode);
  # opening the NVIDIA card too would keep it out of D3 sleep. The by-path name
  # holds colons, which AQ_DRM_DEVICES uses as a separator, so resolve it.
  # GTK apps pick up Adwaita dark, fonts and the accent from the same dconf
  # GNOME writes, via the settings portal; only the cursor needs spelling out.
  xdg.configFile."uwsm/env-hyprland".text = ''
    export AQ_DRM_DEVICES="$(readlink -f /dev/dri/by-path/pci-0000:00:02.0-card)"
    export XCURSOR_THEME=Adwaita
    export XCURSOR_SIZE=24
  '';

  # Written by hand rather than through services.hyprpaper, whose unit is
  # wanted by graphical-session.target and would start under GNOME as well.
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    splash = false
    ipc = false

    wallpaper {
      monitor =
      path = ${wallpaper}
      fit_mode = cover
    }
  '';

  # A GNOME Shell style top bar: black, workspace pills on the left, date and
  # clock (with seconds) in the middle, status indicators on the right.
  programs.waybar = {
    enable = true;
    settings.main = {
      layer = "top";
      position = "top";
      height = 32;
      spacing = 4;
      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [
        "mpris"
        "tray"
        "hyprland/language"
        "network"
        "bluetooth"
        "pulseaudio"
        "battery"
      ];
      "hyprland/workspaces" = {
        format = "{icon}";
        format-icons = {
          default = "●";
          active = "●";
        };
        on-scroll-up = "hyprctl dispatch workspace e-1";
        on-scroll-down = "hyprctl dispatch workspace e+1";
      };
      "hyprland/language" = {
        format = "{variant}";
        format-gb = "en";
        format-colemak = "colemak";
      };
      clock = {
        format = "{:%a %d %b  %H:%M:%S}";
        interval = 1;
        tooltip-format = "<tt>{calendar}</tt>";
      };
      network = {
        format-wifi = "󰖩";
        format-ethernet = "󰈀";
        format-disconnected = "󰖪";
        tooltip-format-wifi = "{essid} ({signalStrength}%)";
      };
      pulseaudio = {
        format = "{icon}";
        format-muted = "󰝟";
        format-icons.default = [
          "󰕿"
          "󰖀"
          "󰕾"
        ];
        tooltip-format = "{volume}%";
        on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        on-click-right = app "pwvucontrol";
      };
      battery = {
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-icons = [
          "󰁺"
          "󰁼"
          "󰁾"
          "󰂀"
          "󰁹"
        ];
      };
      mpris = {
        format = "{status_icon} {dynamic}";
        dynamic-len = 40;
        dynamic-order = [
          "artist"
          "title"
        ];
        status-icons = {
          playing = "󰐊";
          paused = "󰏤";
        };
        tooltip-format = "{player}: {artist} – {title}";
      };
      bluetooth = {
        format = "󰂯";
        format-off = "󰂲";
        format-disabled = "󰂲";
        format-connected = "󰂱 {num_connections}";
        tooltip-format-connected = "{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias}";
        on-click = app "ghostty -e bluetui";
      };
      tray.spacing = 8;
    };
    style = ''
      * {
        font-family: "${font}", "Symbols Nerd Font";
        font-size: 14px;
        font-weight: bold;
        border: none;
        border-radius: 0;
        min-height: 0;
      }

      window#waybar {
        background: #000000;
        color: #${colors.fg};
      }

      #workspaces {
        margin: 6px 8px;
        padding: 0 6px;
        border-radius: 99px;
        background: rgba(255, 255, 255, 0.12);
      }

      #workspaces button {
        padding: 0 3px;
        color: rgba(255, 255, 255, 0.55);
        background: transparent;
        font-size: 9px;
      }

      #workspaces button.active {
        color: #${colors.fg};
      }

      #workspaces button:hover {
        background: transparent;
        box-shadow: none;
        color: #${colors.fg};
      }

      #clock {
        padding: 0 12px;
        border-radius: 99px;
        margin: 4px 0;
      }

      #clock:hover,
      #network:hover,
      #bluetooth:hover,
      #mpris:hover,
      #pulseaudio:hover,
      #battery:hover {
        background: rgba(255, 255, 255, 0.12);
      }

      #tray,
      #language,
      #network,
      #bluetooth,
      #mpris,
      #pulseaudio,
      #battery {
        padding: 0 8px;
        margin: 4px 0;
        border-radius: 99px;
      }

      #battery {
        margin-right: 6px;
      }

      #battery.warning:not(.charging) {
        color: #f8e45c;
      }

      #battery.critical:not(.charging) {
        color: #ff7b63;
      }
    '';
  };

  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "${font}:size=12";
        icon-theme = "Adwaita";
        terminal = "ghostty";
        lines = 10;
        width = 40;
        horizontal-pad = 16;
        vertical-pad = 12;
        inner-pad = 8;
      };
      colors = {
        background = "${colors.popup}f2";
        text = "${colors.fg}ff";
        prompt = "${colors.dim}ff";
        placeholder = "${colors.dim}ff";
        input = "${colors.fg}ff";
        match = "${colors.accent}ff";
        selection = "${colors.accent}ff";
        selection-text = "${colors.fg}ff";
        selection-match = "${colors.fg}ff";
        border = "ffffff1a";
      };
      border = {
        width = 1;
        radius = 12;
      };
    };
  };

  # GNOME Shell banners: top centre, dark card, rounded.
  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;
      anchor = "top-center";
      margin = "8";
      width = 400;
      padding = "12";
      border-size = 1;
      border-radius = 12;
      border-color = "#ffffff1a";
      background-color = "#${colors.popup}";
      text-color = "#${colors.fg}";
      progress-color = "over #${colors.accent}";
      font = "${font} 11";
      icons = true;
      max-icon-size = 48;
    };
  };

  # GNOME-style lock screen: the wallpaper blurred and darkened, a large
  # clock with the date above it, and a pill-shaped password field.
  programs.hyprlock = {
    enable = true;
    settings = {
      general.hide_cursor = true;
      background = [
        {
          path = wallpaper;
          blur_passes = 3;
          blur_size = 8;
          brightness = 0.6;
          color = "rgb(000000)";
        }
      ];
      label = [
        {
          text = "cmd[update:1000] date +%H:%M";
          font_family = font;
          font_size = 96;
          color = "rgb(${colors.fg})";
          position = "0, 220";
          halign = "center";
          valign = "center";
        }
        {
          text = "cmd[update:60000] date '+%A %-d %B'";
          font_family = font;
          font_size = 20;
          color = "rgb(${colors.fg})";
          position = "0, 130";
          halign = "center";
          valign = "center";
        }
      ];
      input-field = [
        {
          size = "300, 44";
          position = "0, -40";
          halign = "center";
          valign = "center";
          rounding = -1;
          outline_thickness = 0;
          inner_color = "rgba(255, 255, 255, 0.15)";
          font_color = "rgb(${colors.fg})";
          check_color = "rgb(${colors.accent})";
          fail_color = "rgb(ff7b63)";
          font_family = font;
          placeholder_text = "Password";
          fade_on_empty = false;
          dots_center = true;
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

  # Media keys and the waybar mpris module act on the most recently active
  # player, which playerctld tracks.
  services.playerctld.enable = true;

  home.packages = with pkgs; [
    brightnessctl
    bluetui
    grim
    hyprpaper
    playerctl
    pwvucontrol
    slurp
    wl-clipboard
  ];
}
