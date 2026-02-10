# Docker socket activation and service dependency fixes

## Problem

Docker starts on boot and creates a serial dependency chain that blocks other services:

```
docker.service (2-5s) -> docker-network-local-dev-proxy.service -> traefik.service
docker.service (2-5s) -> dnsmasq.service
```

Docker is a development tool that doesn't need to be ready before the desktop session. Additionally, dnsmasq's dependency on Docker exists only because it binds to `docker0`, but this can be solved with `bind-dynamic`.

## Changes

### `hosts/thinkpad-x1-g3/default.nix`

```nix
# Docker starts on first use via socket activation, not at boot
virtualisation.docker = {
  enable = true;
  enableOnBoot = false;
};

# Use bind-dynamic so dnsmasq starts without docker0 existing
# and picks up the interface when Docker eventually starts
services.dnsmasq = {
  enable = true;
  alwaysKeepRunning = true;
  settings = {
    interface = [
      "wlp0s20f3"
      "docker0"
    ];
    bind-dynamic = true;   # Replaces bind-interfaces; tolerates missing interfaces
    address = [
      "/test/127.0.0.1"
      "/loc/127.0.0.1"
    ];
  };
};

# Remove dnsmasq's hard dependency on Docker
# (delete these lines from the current config)
# systemd.services.dnsmasq.requires = [ "docker.service" ];
# systemd.services.dnsmasq.after = [ "docker.service" ];

# Docker network creation only when Docker starts, not at boot
systemd.services.docker-network-local-dev-proxy = {
  description = "Create local-dev-proxy Docker network";
  after = [ "docker.service" ];
  requires = [ "docker.service" ];
  wantedBy = lib.mkForce [ "docker.service" ];  # Changed from multi-user.target
  path = [ pkgs.docker ];
  script = ''
    docker network inspect local-dev-proxy >/dev/null 2>&1 || docker network create local-dev-proxy
  '';
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
  };
};

# Traefik starts after graphical session, not on critical boot path
systemd.services.traefik = {
  after = [
    "docker.service"
    "docker-network-local-dev-proxy.service"
    "graphical.target"
  ];
  requires = [ "docker.service" ];
  wants = [ "docker-network-local-dev-proxy.service" ];
};
```

## Rationale

### Socket activation

`docker.socket` listens on `/run/docker.sock`. When any process first connects (e.g., you run `docker ps`), systemd starts `docker.service` on demand. This removes Docker's 2-5 second startup from the critical boot path.

### bind-dynamic

With `bind-dynamic`, dnsmasq binds to interfaces as they appear/disappear dynamically. It can start immediately on `wlp0s20f3` and pick up `docker0` later when Docker starts. This eliminates the hard dependency.

### Traefik after graphical.target

Traefik is a development reverse proxy -- there's no reason for it to block the boot path. Starting it after `graphical.target` ensures the desktop is responsive first.

## Caveat

With `enableOnBoot = false`, containers with `--restart=always` won't auto-restart after reboot until Docker is first triggered. If you have always-restart containers, keep `enableOnBoot = true` but still apply the dnsmasq and Traefik changes.
