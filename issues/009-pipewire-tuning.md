# Tune PipeWire for balanced latency and prevent audio pops

## Problem

Default PipeWire settings use a quantum of 1024 samples (~21ms latency at 48kHz), and ALSA nodes suspend after idle, causing audible pops/clicks when audio resumes after a period of silence.

## Changes

### `hosts/thinkpad-x1-g3/default.nix` -- extend the existing `services.pipewire` block

```nix
services.pipewire = {
  enable = true;
  alsa.enable = true;
  alsa.support32Bit = true;
  pulse.enable = true;

  # Balanced latency: 256 samples @ 48kHz = ~5.3ms
  extraConfig.pipewire."92-low-latency" = {
    "context.properties" = {
      "default.clock.rate" = 48000;
      "default.clock.quantum" = 256;
      "default.clock.min-quantum" = 64;
      "default.clock.max-quantum" = 1024;
    };
  };

  # Match PulseAudio client settings
  extraConfig.pipewire-pulse."92-low-latency" = {
    "pulse.properties" = {
      "pulse.min.req" = "64/48000";
      "pulse.default.req" = "256/48000";
      "pulse.max.req" = "1024/48000";
      "pulse.min.quantum" = "64/48000";
      "pulse.max.quantum" = "1024/48000";
    };
  };

  # Prevent ALSA node suspend (eliminates audio pops on resume)
  wireplumber.extraConfig."99-disable-suspend" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          { "node.name" = "~alsa_output.*"; }
        ];
        actions = {
          update-props = {
            "session.suspend-timeout-seconds" = 0;
          };
        };
      }
      {
        matches = [
          { "node.name" = "~alsa_input.*"; }
        ];
        actions = {
          update-props = {
            "session.suspend-timeout-seconds" = 0;
          };
        };
      }
    ];
  };
};
```

## Rationale

### Quantum 256

- Default quantum 1024 = ~21ms latency. Quantum 256 = ~5.3ms -- noticeably more responsive for video calls, music production (Audacity, DaVinci Resolve), and gaming.
- `min-quantum = 64` allows applications that request lower latency (games, pro audio) to go down to ~1.3ms.
- `max-quantum = 1024` allows power-saving upscaling during passive playback.
- This is a safe middle ground -- aggressive low-latency (quantum 32-64) risks underruns/glitches.

### Disable suspend

When ALSA nodes suspend after idle, the codec powers down. Resuming causes an audible pop/click on many laptop speakers and headphone DACs. Setting `session.suspend-timeout-seconds = 0` keeps nodes active, trading minimal power for click-free audio.

## Note

For audio production with DaVinci Resolve or Audacity, if you need even lower latency, decrease `default.clock.quantum` to 128 or 64 and test for underruns.
