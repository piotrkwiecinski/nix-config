{ inputs, self, ... }:
let
  mkHome =
    {
      username,
      hostname,
      system ? "x86_64-linux",
    }:
    inputs.home-manager.lib.homeManagerConfiguration {
      modules = [ ../home/${username}/${hostname}.nix ];
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          inputs.emacs-overlay.overlays.default
          self.overlays.default
        ];
      };
      extraSpecialArgs = {
        inherit inputs;
        outputs = self;
      };
    };
in
{
  flake.homeConfigurations = {
    "piotr@homelab" = mkHome {
      username = "piotr";
      hostname = "homelab";
    };
    "piotr@thinkpad-x1-g3" = mkHome {
      username = "piotr";
      hostname = "thinkpad-x1-g3";
    };
    "piotr@homeserver" = mkHome {
      username = "piotr";
      hostname = "homeserver";
      system = "aarch64-linux";
    };
  };
}
