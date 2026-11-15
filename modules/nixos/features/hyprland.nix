# Hyprland as an extra session next to GNOME: GDM lists it as
# "Hyprland (uwsm-managed)". The user-side config lives in
# home/piotr/features/desktop/hyprland.
{ pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    # UWSM runs the compositor as a systemd session, so
    # graphical-session.target and the user environment are set up as under GNOME.
    withUWSM = true;
  };

  # The GNOME portal stays the default for GNOME; Hyprland sessions use its own
  # portal (screencast, screenshots) with GTK for file pickers.
  xdg.portal.config.hyprland.default = [
    "hyprland"
    "gtk"
  ];

  environment.systemPackages = [ pkgs.hyprpolkitagent ];
}
