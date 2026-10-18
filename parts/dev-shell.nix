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
        ];
      };
    };
}
