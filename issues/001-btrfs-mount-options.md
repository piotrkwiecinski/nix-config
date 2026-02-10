# Btrfs mount options for NVMe and data drives

## Problem

The root NVMe btrfs subvolume `@` and all three data drive subvolumes have **no mount options** specified. This means btrfs defaults apply, missing easy performance and space-saving wins.

## Changes

### `hosts/thinkpad-x1-g3/disk-config.nix` -- root NVMe subvolume

Add `mountOptions` to the `@` subvolume:

```nix
"@" = {
  mountpoint = "/";
  mountOptions = [
    "noatime"          # Eliminates unnecessary write I/O on every file read
    "compress=zstd:1"  # Low-overhead compression; major space savings on /nix/store
  ];
};
```

### `hosts/thinkpad-x1-g3/disk-config.nix` -- data drive subvolumes

Add `noatime` and `compress=zstd:3` to each data mount:

```nix
fileSystems."/data/backups" = {
  device = "/dev/disk/by-uuid/d83ca419-d19d-428d-a89c-e6b80cad73d4";
  fsType = "btrfs";
  options = [ "subvol=@backups" "noatime" "compress=zstd:3" ];
};

fileSystems."/data/shared" = {
  device = "/dev/disk/by-uuid/d83ca419-d19d-428d-a89c-e6b80cad73d4";
  fsType = "btrfs";
  options = [ "subvol=@shared" "noatime" "compress=zstd:3" ];
};

fileSystems."/data/media" = {
  device = "/dev/disk/by-uuid/d83ca419-d19d-428d-a89c-e6b80cad73d4";
  fsType = "btrfs";
  options = [ "subvol=@media" "noatime" "compress=zstd:3" ];
};
```

## Rationale

- **`noatime`**: Prevents updating access-time metadata on every read. Eliminates pointless write I/O, especially impactful for the read-heavy Nix store.
- **`compress=zstd:1`** (root NVMe): Minimal CPU overhead with meaningful space savings. The Nix store compresses extremely well (20-40% space savings). Level 1 is recommended for fast NVMe drives.
- **`compress=zstd:3`** (data drive): Slightly higher compression for secondary storage where throughput pressure is lower.

### What NOT to add (already defaults on kernel 6.18)

- `discard=async` -- auto-enabled since kernel 6.2 for capable SSDs
- `space_cache=v2` -- default since btrfs-progs 5.15
- `ssd` -- auto-detected for non-rotational devices

## Notes

- Compression only affects **newly written** data. To retroactively compress existing files: `btrfs filesystem defragment -r -czstd /path` (one-time, manual operation).
- The nixos-hardware module already enables `services.fstrim`, which is redundant with `discard=async` but harmless.
