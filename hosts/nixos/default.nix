{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core
    ../../modules/profiles/desktop.nix
    ../../modules/integrations/home-manager.nix
    ../../modules/features/development/opencode.nix
    ../../modules/features/virtualization/vmware-guest.nix
  ];

  home-manager.users.ryuk.imports = [
    ../../home/features/codex.nix
  ];

  my.programs.opencode.enable = false;

  networking.hostName = "nixos";

  # Never change this value during a normal system upgrade.
  system.stateVersion = "26.05";
}
