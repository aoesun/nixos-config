{ ... }:
{
  boot.loader = {
    systemd-boot = {
      enable = true;
      # Limit boot entries while keeping enough rollback points.
      configurationLimit = 5;
    };
    efi.canTouchEfiVariables = true;
  };

  # Remove old, unreachable store paths on a predictable schedule.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
