# GNOME workstation.
{
  # input: raw /dev/input access (every keyboard), so desktops only
  users.users.piotr.extraGroups = [
    "audio"
    "video"
    "input"
  ];

  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.xserver.xkb = {
    layout = "gb";
    variant = "colemak";
  };
  console.keyMap = "uk";

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # module-x11-bell segfaults pipewire when Xwayland goes away (every
    # greeter hand-off and logout); the bell sound isn't worth it.
    extraConfig.pipewire."99-no-x11-bell"."context.properties"."module.x11.bell" = false;
  };
}
