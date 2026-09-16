{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core
    ../../modules/desktop
    ../../modules/home-manager.nix
    ../../modules/virtualization/vmware-guest.nix
  ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      # Limit boot entries while keeping enough rollback points.
      configurationLimit = 5;
    };
    efi.canTouchEfiVariables = true;
  };

  networking.hostName = "nixos";

  # Keep both sessions available while evaluating Niri. Change this to
  # "plasma" or "niri" once a single desktop should own the host.
  desktop.session = "niri";

  # Never change this value during a normal system upgrade.
  system.stateVersion = "26.05";
}
