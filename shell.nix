{
  pkgs ?
    let
      lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
      nixpkgs = fetchTarball {
        url = "https://github.com/nixos/nixpkgs/archive/${lock.rev}.tar.gz";
        sha256 = lock.narHash;
      };
    in
    import nixpkgs { overlays = [ ]; },
}:
{
  default = pkgs.mkShellNoCC {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes auto-allocate-uids";
    packages = with pkgs; [
      git
      home-manager
      nil
      (pkgs.writeShellApplication {
        name = "home-switch";
        text = ''
          home-manager switch -b backup --impure --flake ".#$(whoami)@$(hostname)"
        '';
      })
      (pkgs.writeShellApplication {
        name = "nix-switch";
        text = ''
          sudo nixos-rebuild switch --flake ".#$(hostname)"
        '';
      })
    ];
  };
}
