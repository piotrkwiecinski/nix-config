{ ... }:
{
  programs.mpv = {
    enable = true;
    config = {
      vo = "gpu-next";
      hwdec = "auto-safe";
      profile = "high-quality";
      deband = true;
      deband-iterations = 4;
      deband-range = 16;
      blend-subtitles = true;
      sub-ass-override = "no";
      save-position-on-quit = true;
    };
    bindings = {
      b = "cycle deband";
    };
  };
}
