{ config, username, ... }:
{
  services.samba = {
    enable = true;
    # Opens TCP 139/445 and UDP 137/138.
    openFirewall = true;

    settings = {
      global = {
        "server string" = "nixos";
        "map to guest" = "Bad User";
        "server min protocol" = "SMB2";
      };

      Public = {
        path = "${config.users.users.${username}.home}/Public";
        browseable = "yes";
        "read only" = "yes";
        "guest ok" = "yes";
        # The home directory is 0700, so the anonymous nobody user cannot
        # traverse it. Serve this read-only share as the owning user instead.
        "force user" = username;
      };
    };
  };

  # Keep the machine SID and any smbpasswd accounts across root resets.
  # This is inert on hosts that do not enable impermanence.
  environment.persistence."/persist".directories = [ "/var/lib/samba" ];
}
