{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      # VM tests need KVM; they run on the x86_64 thinkpad.
      checks = lib.optionalAttrs pkgs.stdenv.hostPlatform.isx86_64 {
        backup-restore = import ../checks/backup-restore.nix { inherit pkgs; };
      };
    };
}
