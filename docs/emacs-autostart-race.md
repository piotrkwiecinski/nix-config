# Emacs autostart race with `emacs.socket`

## Symptom

After login on GNOME Wayland, no Emacs frame appears on screen even though
`systemctl --user status emacs.service` shows the daemon as active and
`emacsclient --eval '(emacs-version)'` works from a terminal.

## Root cause

Two user-level units race at session start:

- **`emacs.socket`** (from `services.emacs` in
  `home/piotr/features/emacs/default.nix`) — socket-activated; the daemon
  only starts when something first connects to `/run/user/1000/emacs/server`.
- **`autostart/emacsclient.desktop`** (declared in `home/piotr/thinkpad-x1-g3.nix`)
  — runs `emacsclient -c` via the XDG autostart mechanism, which the GNOME
  session launches shortly after login.

If `emacsclient -c` fires before `emacs.socket` has been reached in the user
systemd target graph, the client either blocks, fails silently, or connects
to a partial daemon and never opens a frame. The daemon is still eventually
started (by the first later connection), but no initial window is created,
so it looks like "Emacs didn't start".

## Reproduction

1. Log out of GNOME (Wayland).
2. Log back in.
3. Observe: no Emacs window on the default workspace.
4. `systemctl --user status emacs.service` → `active (running)`.
5. `emacsclient -c &` in a terminal → frame appears normally.

## Fix options

**Option A — make the autostart wait for the socket (preferred)**

Replace the XDG autostart `.desktop` with a user systemd service that is
ordered after `emacs.socket`:

```nix
systemd.user.services.emacsclient-frame = {
  Unit = {
    Description = "Open an Emacs frame on login";
    After = [ "emacs.socket" "graphical-session.target" ];
    Requires = [ "emacs.socket" ];
    PartOf = [ "graphical-session.target" ];
  };
  Service = {
    Type = "forking";
    ExecStart = "${pkgs.emacs}/bin/emacsclient -c -n";
  };
  Install.WantedBy = [ "graphical-session.target" ];
};
```

Drop the `xdg.configFile."autostart/emacsclient.desktop"` block in
`home/piotr/thinkpad-x1-g3.nix` once this is in place.

**Option B — tell XDG to delay the client**

Add an `X-GNOME-Autostart-Delay=3` line to the existing `.desktop` entry.
Cheaper but fragile: 3 s may not be enough on a cold boot, and the value
is a guess rather than a dependency.

**Option C — drop the autostart entirely**

Rely on `emacs.socket` being activated on demand (e.g. by EDITOR or a
hotkey that runs `emacsclient -c`). Trade-off: no Emacs frame on the
workspace by default after login.

## Related files

- `home/piotr/thinkpad-x1-g3.nix` — `xdg.configFile."autostart/emacsclient.desktop"`
  stanza declaring the current autostart entry.
- `home/piotr/features/emacs/default.nix` — `services.emacs.socketActivation.enable = true;`
  that creates the socket unit.

## Status

Open. Workaround: run `emacsclient -c &` from a terminal after login.
