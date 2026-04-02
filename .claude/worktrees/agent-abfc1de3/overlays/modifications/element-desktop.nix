{ inputs }:
final: prev: {
  unstable = prev.unstable // {
    element-desktop = prev.unstable.element-desktop.overrideAttrs (oldAttrs: {
      postFixup = (oldAttrs.postFixup or "") + ''
        wrapProgram $out/bin/element-desktop \
          --add-flags "--password-store=gnome-libsecret"
      '';
    });
  };
}
