{ ... }:
{
  environment.persistence."/persist" = {
    # Keep the complete policy evaluated without creating any mounts yet.
    enable = false;
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

    users.ryuk = {
      files = [
        ".zsh_history"
      ];

      directories = [
        # Personal data.
        "Desktop"
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Videos"

        # Credentials and desktop secrets.
        {
          directory = ".ssh";
          mode = "0700";
        }
        {
          directory = ".gnupg";
          mode = "0700";
        }
        ".local/share/keyrings"

        # Application state worth retaining. Caches are intentionally omitted
        # so an ephemeral system can recreate them when needed.
        ".config/Bitwarden"
        ".config/chromium"
        ".config/spotify"
        ".local/share/direnv"
      ];
    };
  };
}
