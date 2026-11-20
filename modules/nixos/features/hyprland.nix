# Hyprland as an extra session next to GNOME: GDM lists it as
# "Hyprland (uwsm-managed)". The user-side config lives in
# home/piotr/features/desktop/hyprland.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  hyprland = config.programs.hyprland.package;

  # The Hyprland package ships two sessions; GDM should offer only the UWSM one.
  # Plain "Hyprland" skips UWSM, so exec-once `uwsm app` helpers fail and
  # ~/.config/uwsm/env-hyprland (iGPU pinning) is never read.
  uwsmSessionOnly =
    pkgs.runCommand "hyprland-uwsm-session"
      {
        passthru.providedSessions = [ "hyprland-uwsm" ];
        preferLocalBuild = true;
      }
      ''
        mkdir -p $out/share/wayland-sessions
        ln -s ${hyprland}/share/wayland-sessions/hyprland-uwsm.desktop $out/share/wayland-sessions/
      '';
in
{
  # Swap the Hyprland package for the stub in the display manager's session
  # list only. hyprland-uwsm.desktop runs `uwsm start ... hyprland.desktop`, and
  # UWSM still finds that entry via /run/current-system/sw/share/wayland-sessions.
  # sessionPackages declares no `apply`, so this extra declaration may add one.
  options.services.displayManager.sessionPackages = lib.mkOption {
    apply = map (p: if p.outPath == hyprland.outPath then uwsmSessionOnly else p);
  };

  config.programs.hyprland = {
    enable = true;
    # UWSM runs the compositor as a systemd session, so
    # graphical-session.target and the user environment are set up as under GNOME.
    withUWSM = true;
  };

  # The GNOME portal stays the default for GNOME; Hyprland sessions use its own
  # portal (screencast, screenshots) with GTK for file pickers.
  config.xdg.portal.config.hyprland.default = [
    "hyprland"
    "gtk"
  ];

  # At logout something re-activates xdg-desktop-portal over D-Bus after
  # graphical-session.target has stopped; it then starts these backends with
  # no display left, each exits 1 five times and hits its start limit.
  # Requisite makes the start fail at once (no exec, no restart loop) unless
  # the session is up. Drop-ins on the packaged units, so the rest of each
  # unit stays upstream's.
  config.systemd.user.services =
    lib.genAttrs
      [
        "xdg-desktop-portal-gtk"
        "xdg-desktop-portal-hyprland"
      ]
      (_: {
        requisite = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
      });

  config.environment.systemPackages = [ pkgs.hyprpolkitagent ];
}
