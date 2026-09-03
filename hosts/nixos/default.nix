{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/ssh.nix
    ../../modules/nixos/home-manager.nix
  ];

  # Never change this value during a normal system upgrade.
  system.stateVersion = "26.05";
}
