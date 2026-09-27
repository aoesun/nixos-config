{ lib, pkgs, ... }:

{
  # Installation-time disk layout for the future 64 GiB system disk.
  #
  # This file is intentionally not imported by the running host yet. Before
  # using Disko, replace the placeholder below with the target disk's stable
  # /dev/disk/by-id path and verify it from the installation environment.
  disko.devices.disk.system = {
    type = "disk";
    device = lib.mkDefault "/dev/disk/by-id/REPLACE_WITH_TARGET_DISK";

    content = {
      type = "gpt";

      partitions = {
        ESP = {
          priority = 1;
          name = "ESP";
          start = "1M";
          size = "1G";
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

        system = {
          priority = 2;
          name = "system";
          size = "100%";

          content = {
            type = "btrfs";
            extraArgs = [
              "-f"
              "-L"
              "nixos"
            ];

            # Keep these as sibling subvolumes. Only /root is recreated at
            # boot; /home, /nix, /persist, and /swap remain intact.
            subvolumes = {
              "/root" = {
                mountpoint = "/";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };

              "/home" = {
                mountpoint = "/home";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };

              "/nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };

              "/persist" = {
                mountpoint = "/persist";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };

              "/swap" = {
                mountpoint = "/.swapvol";
                mountOptions = [ "noatime" ];
                swap.swapfile.size = "8G";
              };
            };
          };
        };
      };
    };
  };

  # Importing this installation layout opts the host into Impermanence. The
  # shared policy remains disabled on the current VM, where this file is not
  # imported.
  environment.persistence."/persist".enable = true;

  # Restore the writable root subvolume from the read-only root-blank snapshot
  # before it is mounted. The installation guide creates that snapshot after
  # Disko formats the target disk and before nixos-install populates /root.
  boot.initrd.systemd.services.impermanence-root-rollback = {
    description = "Restore the ephemeral Btrfs root subvolume";
    requiredBy = [ "sysroot.mount" ];
    before = [ "sysroot.mount" ];
    after = [ "dev-disk-by\\x2dlabel-nixos.device" ];
    unitConfig.DefaultDependencies = "no";
    path = [
      pkgs.btrfs-progs
      pkgs.coreutils
      pkgs.util-linux
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /btrfs_tmp
      mount -t btrfs -o subvolid=5 /dev/disk/by-label/nixos /btrfs_tmp

      if ! btrfs subvolume show /btrfs_tmp/root-blank >/dev/null 2>&1; then
        echo "Impermanence: missing Btrfs snapshot /root-blank" >&2
        umount /btrfs_tmp
        exit 1
      fi

      if btrfs subvolume show /btrfs_tmp/root >/dev/null 2>&1; then
        btrfs subvolume delete --recursive /btrfs_tmp/root
      fi

      btrfs subvolume snapshot /btrfs_tmp/root-blank /btrfs_tmp/root
      umount /btrfs_tmp
    '';
  };

  # Impermanence prepares bind mounts during early boot. Both the persistence
  # store and filesystems containing its mount targets must be available then.
  fileSystems."/".neededForBoot = true;
  fileSystems."/persist".neededForBoot = true;
  fileSystems."/home".neededForBoot = true;

  # Periodic TRIM is a conservative default for SSD-backed physical and
  # virtual disks.
  services.fstrim.enable = true;
}
