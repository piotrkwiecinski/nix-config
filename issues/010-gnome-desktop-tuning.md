# GNOME desktop performance tuning via dconf

## Problem

Default GNOME settings include animations, active search providers for unused apps, and no VRR (variable refresh rate). These can be tuned for a snappier desktop experience.

## Changes

### `home/piotr/thinkpad-x1-g3.nix` -- add inside the main attribute set

```nix
dconf.settings = {
  # Enable Variable Refresh Rate for reduced input latency and no tearing
  "org/gnome/mutter" = {
    experimental-features = [
      "variable-refresh-rate"
    ];
  };

  # Optional: disable animations for snappier feel (comment out if you prefer animations)
  "org/gnome/desktop/interface" = {
    enable-animations = false;
  };

  # Disable GNOME Software background update checking
  "org/gnome/software" = {
    download-updates = false;
    allow-updates = false;
  };

  # Disable search providers for apps not used in Activities search
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
```

### If using a 4K display with fractional scaling

Add these to the `experimental-features` list:

```nix
"org/gnome/mutter" = {
  experimental-features = [
    "variable-refresh-rate"
    "scale-monitor-framebuffer"     # Better fractional scaling quality
    "xwayland-native-scaling"       # Native scaling for XWayland apps
  ];
};
```

## Rationale

### Variable Refresh Rate

VRR eliminates screen tearing and reduces perceived input latency by synchronizing the display refresh with frame delivery. Requires a VRR-capable display (many ThinkPad X1 Extreme Gen 3 displays support it).

### Disable animations

Removes the ~250ms animation delay on window open/close/switch. Purely subjective -- some prefer animations for visual continuity. The desktop feels noticeably snappier without them.

### Search providers

Each enabled search provider indexes content in the background and responds to Activities overview searches. Disabling unused providers reduces background CPU/memory usage and makes search results less cluttered.

### GNOME Software

Prevents background package update checking, which is redundant on NixOS (package updates are done via `nix-switch`).
