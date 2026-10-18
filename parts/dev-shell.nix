{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShellNoCC {
        NIX_CONFIG = "extra-experimental-features = nix-command flakes auto-allocate-uids";
        # Tracked hooks, e.g. the commit-msg guard against leaking private
        # flake details into this public history.
        shellHook = ''
          git config core.hooksPath .githooks
        '';
        packages = with pkgs; [
          git
          nil
          sops
          (writeShellApplication {
            name = "nix-switch";
            text = ''nixos-rebuild switch --sudo --flake ".#$(hostname)"'';
          })
          # A Pi rebuilds itself from its ~/nix-config clone (push first). The
          # switch runs as a transient unit, so a Wi-Fi drop during activation
          # cannot kill it; --wait returns its result, --collect drops a failed
          # unit so the next run can reuse the name.
          (writeShellApplication {
            name = "pi-switch";
            runtimeInputs = [ openssh ];
            text = ''
              host=''${1:?usage: pi-switch <homeserver|homerpilab>}
              ssh "piotr@$host" bash -s -- "$host" <<'EOF'
              set -euo pipefail
              cd ~/nix-config
              git pull --ff-only
              journalctl -fu nixos-rebuild-manual -n0 &
              trap 'kill $!' EXIT
              sudo systemd-run --unit=nixos-rebuild-manual --wait --collect \
                --working-directory=/home/piotr/nix-config --setenv=HOME=/root \
                --setenv=PATH=/run/current-system/sw/bin:/home/piotr/.nix-profile/bin \
                --property=Type=exec \
                /run/current-system/sw/bin/nixos-rebuild switch --flake "/home/piotr/nix-config#$1"
              EOF
            '';
          })
          # Fallback for a Pi without its clone or token yet: evaluate here,
          # build and activate on the Pi.
          (writeShellApplication {
            name = "pi-deploy";
            text = ''
              host=''${1:?usage: pi-deploy <homeserver|homerpilab>}
              nixos-rebuild switch --flake ".#$host" --build-host "piotr@$host" --target-host "piotr@$host" --sudo
            '';
          })
        ];
      };
    };
}
