# Declarative disk layout for disko (adoption — do NOT run disko format on this disk).
# Dual-boot with Windows; only NixOS partitions (p5, p6) have content defined.
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/nvme1n1";
      content = {
        type = "gpt";
        partitions = {
          windows-esp = {
            size = "260M";
            type = "EF00";
          };
          microsoft-reserved = {
            size = "16M";
            type = "0C01";
          };
          windows = {
            size = "351.4G";
            type = "0700";
          };
          windows-recovery = {
            size = "1.2G";
            type = "2700";
          };
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "fmask=0077"
                "dmask=0077"
              ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
    };
  };
}
