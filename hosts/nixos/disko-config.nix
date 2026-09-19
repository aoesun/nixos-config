{ lib, ... }:

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

            # Keep these as sibling subvolumes. The root subvolume can later
            # be recreated at boot without touching persistent state.
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

  # Impermanence may need persistent state during the early boot process.
  fileSystems."/persist".neededForBoot = true;

  # Periodic TRIM is a conservative default for SSD-backed physical and
  # virtual disks.
  services.fstrim.enable = true;
}
