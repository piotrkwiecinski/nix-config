{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShellNoCC {
        NIX_CONFIG = "extra-experimental-features = nix-command flakes auto-allocate-uids";
        packages = with pkgs; [
          git
          home-manager
          nil
          sops
          (writeShellApplication {
            name = "home-switch";
            text = ''home-manager switch -b backup --flake ".#$(whoami)@$(hostname)"'';
          })
          (writeShellApplication {
            name = "nix-switch";
            text = ''sudo nixos-rebuild switch --flake ".#$(hostname)"'';
          })
        ];
      };
    };
}
