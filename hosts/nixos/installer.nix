{ lib, ... }:
{
  imports = [
    ./disko-config.nix
    ../../modules/core/impermanence.nix
  ];

  # These modules cover the default VMware virtual SCSI/SATA controllers. The
  # final host receives its exact list from nixos-generate-config.
  boot.initrd.availableKernelModules = [
    "mptspi"
    "ahci"
    "sd_mod"
    "sr_mod"
  ];

  # Satisfy the complete NixOS configuration checks even though this output is
  # only used by Disko and is never installed as the final system.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "26.05";
}
