{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    {
      packages = import ../pkgs inputs.nixpkgs.legacyPackages.${system};
    };
}
