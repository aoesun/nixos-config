{ lib, ... }:

{
  # Disk layout for a single-disk 64 GiB VMware guest. Verify /dev/sda from the
  # installation environment before running any destructive Disko command.
  disko.devices.disk.system = {
    type = "disk";
    device = lib.mkDefault "/dev/sda";

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
            # modules/core/impermanence.nix finds the filesystem by this label.
            extraArgs = [
              "-f"
              "-L"
              "nixos"
            ];

            # Disko runs this after creating all subvolumes and before mounting
            # them. Preserve the initial empty root as the rollback template.
            postCreateHook = ''
              MNTPOINT=$(mktemp -d)
              mount "$device" "$MNTPOINT" -o subvol=/
              trap 'umount "$MNTPOINT"; rmdir "$MNTPOINT"' EXIT

              if ! btrfs subvolume show "$MNTPOINT/root-blank" >/dev/null 2>&1; then
                btrfs subvolume snapshot -r \
                  "$MNTPOINT/root" \
                  "$MNTPOINT/root-blank"
              fi
            '';

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
}
