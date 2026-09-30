{ lib, ... }:
{
  environment.persistence."/persist" = {
    # The current VM keeps this disabled. Importing the Disko layout for a new
    # installation enables it there, so evaluating this shared module is safe.
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
