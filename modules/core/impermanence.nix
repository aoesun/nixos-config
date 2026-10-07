{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.environment.persistence."/persist";

  # Label of the Btrfs filesystem holding the root, root-blank, home, and
  # persist subvolumes, as created by the host's Disko layout.
  btrfsLabel = "nixos";
  btrfsDevice = "/dev/disk/by-label/${btrfsLabel}";
in
{
  config = lib.mkMerge [
    {
      environment.persistence."/persist" = {
        # Hosts opt in explicitly once their disk provides a root-blank snapshot.
        enable = lib.mkDefault false;
        hideMounts = true;

        # System identity and host keys must survive root filesystem resets.
        files = [
          "/etc/machine-id"

          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_ed25519_key.pub"
          "/etc/ssh/ssh_host_rsa_key"
          "/etc/ssh/ssh_host_rsa_key.pub"
        ];

        directories = [
          # Operational state that should remain available across reboots.
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
          "/var/log"

          # Persistent timers such as nix.gc would otherwise forget their last
          # run and fire on every boot.
          "/var/lib/systemd/timers"

          # Saved Wi-Fi and VPN connections contain secrets.
          {
            directory = "/etc/NetworkManager/system-connections";
            mode = "0700";
          }
        ];

        # /home is a separate persistent Btrfs subvolume in the conservative
        # layout, so user files do not need a second set of bind mounts here.
      };
    }

    (lib.mkIf cfg.enable {
      # Restore the writable root subvolume from the read-only root-blank
      # snapshot before it is mounted.
      boot.initrd.systemd.services.impermanence-root-rollback = {
        description = "Restore the ephemeral Btrfs root subvolume";
        requiredBy = [ "sysroot.mount" ];
        before = [ "sysroot.mount" ];
        requires = [ "dev-disk-by\\x2dlabel-${btrfsLabel}.device" ];
        after = [ "dev-disk-by\\x2dlabel-${btrfsLabel}.device" ];
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
          mount -t btrfs -o subvolid=5 ${btrfsDevice} /btrfs_tmp

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

      # Impermanence prepares bind mounts during early boot. Both the
      # persistence store and filesystems containing its mount targets must be
      # available then.
      fileSystems."/".neededForBoot = true;
      fileSystems."/persist".neededForBoot = true;
      fileSystems."/home".neededForBoot = true;
    })
  ];
}
