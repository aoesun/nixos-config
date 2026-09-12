{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core
    ../../modules/profiles/desktop.nix
    ../../modules/integrations/home-manager.nix
    ../../modules/nixos/optional/vmware-guest.nix
  ];

  networking.hostName = "nixos";

  # Never change this value during a normal system upgrade.
  system.stateVersion = "26.05";
}
