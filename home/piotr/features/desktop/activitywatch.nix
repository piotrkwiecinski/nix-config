{ pkgs, lib, ... }:
let
  awServerHost = "127.0.0.1";
  awServerPort = 5600;
  remoteAw = "http://homeserver:5600";

  awSyncScript = pkgs.writeShellApplication {
    name = "aw-sync-push";
    runtimeInputs = with pkgs; [
      curl
      jq
    ];
    text = ''
      set -euo pipefail

      LOCAL="http://${awServerHost}:${toString awServerPort}"
      REMOTE="${remoteAw}"

      if ! curl -fsS --max-time 5 "$REMOTE/api/0/info" >/dev/null; then
        echo "remote aw-server $REMOTE unreachable, skipping"
        exit 0
      fi

      buckets=$(curl -fsS "$LOCAL/api/0/buckets/" | jq -r 'keys[]')
      for bucket in $buckets; do
        export_json=$(curl -fsS "$LOCAL/api/0/buckets/$bucket/export")
        # aw-server /import accepts the same shape /export returns
        if echo "$export_json" | curl -fsS -X POST \
            -H "Content-Type: application/json" \
            --data-binary @- \
            "$REMOTE/api/0/import" >/dev/null; then
          echo "pushed $bucket"
        else
          echo "failed to push $bucket" >&2
        fi
      done
    '';
  };

  # GNOME Wayland window watcher. Polls the focused-window-dbus extension
  # (org.gnome.shell.extensions.FocusedWindow) via gdbus and POSTs heartbeats
  # to aw-server. Replaces the upstream xlib-only aw-watcher-window 0.13.2
  # on GNOME Wayland, where it crashes with AttributeError on xlib.get_window_name.
  # Requires the GNOME Shell extension focused-window-dbus@flexagoon.com to be
  # enabled (installed+enabled via this module's home.packages + dconf).
  gnomeWindowWatcherPython = pkgs.python3.withPackages (p: [ p.requests ]);
  gnomeWindowWatcher = pkgs.writeShellApplication {
    name = "aw-watcher-window-gnome";
    runtimeInputs = [
      gnomeWindowWatcherPython
      pkgs.glib
    ];
    text = ''
      export AW_SERVER_URL="http://${awServerHost}:${toString awServerPort}"
      exec python3 ${./aw-watcher-window-gnome.py}
    '';
  };
in
{
  # Installs the extension into ~/.nix-profile/share/gnome-shell/extensions.
  # Enable it manually once via GNOME Extensions (do not set enabled-extensions
  # here - home-manager's dconf lists are replace-only, which would clobber
  # any other extensions enabled via the GUI).
  home.packages = [ pkgs.gnomeExtensions.focused-window-d-bus ];

  systemd.user.services.aw-server = {
    Unit = {
      Description = "ActivityWatch server (aw-server-rust)";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.aw-server-rust}/bin/aw-server --host ${awServerHost} --port ${toString awServerPort}";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.aw-watcher-window = {
    Unit = {
      Description = "ActivityWatch window watcher (GNOME Wayland via focused-window-dbus)";
      After = [
        "aw-server.service"
        "graphical-session.target"
      ];
      Requires = [ "aw-server.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${gnomeWindowWatcher}/bin/aw-watcher-window-gnome";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.aw-watcher-afk = {
    Unit = {
      Description = "ActivityWatch AFK watcher";
      After = [ "aw-server.service" ];
      Requires = [ "aw-server.service" ];
    };
    Service = {
      ExecStart = "${pkgs.aw-watcher-afk}/bin/aw-watcher-afk --host ${awServerHost} --port ${toString awServerPort}";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.aw-sync = {
    Unit = {
      Description = "Push ActivityWatch buckets to homeserver aggregator";
      After = [
        "aw-server.service"
        "network-online.target"
      ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${awSyncScript}/bin/aw-sync-push";
    };
  };

  systemd.user.timers.aw-sync = {
    Unit.Description = "Periodic ActivityWatch push to homeserver";
    Timer = {
      OnBootSec = "2min";
      OnUnitActiveSec = "10min";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
