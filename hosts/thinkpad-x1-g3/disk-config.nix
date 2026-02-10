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
                  mountOptions = [
                    "noatime"
                    "compress=zstd:1"
                  ];
                };
              };
            };
          };
        };
      };
    };
  };

  # 1TB data drive — btrfs subvolumes (already formatted, adoption only)
  fileSystems."/data/backups" = {
    device = "/dev/disk/by-uuid/d83ca419-d19d-428d-a89c-e6b80cad73d4";
    fsType = "btrfs";
    options = [
      "subvol=@backups"
      "noatime"
      "compress=zstd:3"
    ];
  };

  fileSystems."/data/shared" = {
    device = "/dev/disk/by-uuid/d83ca419-d19d-428d-a89c-e6b80cad73d4";
    fsType = "btrfs";
    options = [
      "subvol=@shared"
      "noatime"
      "compress=zstd:3"
    ];
  };

  fileSystems."/data/media" = {
    device = "/dev/disk/by-uuid/d83ca419-d19d-428d-a89c-e6b80cad73d4";
    fsType = "btrfs";
    options = [
      "subvol=@media"
      "noatime"
      "compress=zstd:3"
    ];
  };
}
