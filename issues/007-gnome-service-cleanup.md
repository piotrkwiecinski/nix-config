# Disable unnecessary GNOME services and fix XDG portal

## Problem

The default GNOME desktop enables many background services that consume CPU, RAM (250-900MB combined), and I/O without providing value for this workstation setup. Additionally, `xdg.portal.wlr.enable = true` installs the wlroots portal which conflicts with GNOME's portal.

## Changes

### `hosts/thinkpad-x1-g3/default.nix`

```nix
# Disable GNOME services not needed for this workstation
services.gnome.localsearch.enable = false;          # File indexer (formerly tracker-miners) -- major CPU/IO hog
services.gnome.tinysparql.enable = false;            # SPARQL database for localsearch
services.gnome.gnome-browser-connector.enable = false;  # Browser extension connector
services.gnome.gnome-initial-setup.enable = false;   # First-run wizard
services.gnome.gnome-remote-desktop.enable = false;  # RDP/VNC server
services.gnome.rygel.enable = false;                 # UPnP media server
services.gnome.gnome-user-share.enable = false;      # WebDAV file sharing

# Fix XDG portals -- remove wlr portal (for wlroots compositors, not GNOME)
xdg.portal = {
  enable = true;
  # wlr.enable = true;  # REMOVE: conflicts with GNOME portal
  extraPortals = with pkgs; [
    xdg-desktop-portal-gnome
  ];
};
```

## Rationale

### localsearch / tinysparql (formerly tracker-miners / tracker)

The file indexer continuously crawls the filesystem, consuming 100-500MB RAM and causing I/O spikes. In NixOS 25.11, these were renamed from `tracker-miners` and `tracker`. Unless you use GNOME's file search in Nautilus or Activities overview, these provide no benefit.

### Other GNOME services

| Service | RAM usage | Purpose | Why disable |
|---|---|---|---|
| localsearch | 100-500 MB | File indexing | Not needed; Emacs/ripgrep for search |
| tinysparql | 30-80 MB | SPARQL DB for localsearch | Dependency of localsearch |
| gnome-browser-connector | ~10 MB | Firefox/Chrome GNOME extensions | Not used |
| gnome-initial-setup | ~20 MB | First-run wizard | Already set up |
| gnome-remote-desktop | ~15 MB | RDP/VNC | Not needed |
| rygel | 10-30 MB | UPnP media server | Not needed |
| gnome-user-share | ~10 MB | WebDAV sharing | Not needed |

### XDG portal conflict

`xdg-desktop-portal-wlr` is designed for wlroots-based compositors (Sway, Hyprland). GNOME uses Mutter, which provides its own portal via `xdg-desktop-portal-gnome`. Having both creates duplicated portal interfaces and can cause screen sharing, file dialogs, and other portal-mediated features to misbehave.

## Optional: also disable if not used

```nix
# Only if you don't use GNOME Online Accounts (Google, Microsoft, etc.)
services.gnome.gnome-online-accounts.enable = false;

# Only if you don't use GNOME Calendar/Contacts
services.gnome.evolution-data-server.enable = false;

# Only if you don't use GNOME Software center
services.gnome.gnome-software.enable = false;
```
