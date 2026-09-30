{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
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

  # Let `nh os` commands find this host's Flake without an explicit path.
  programs.nh.flake = "/home/ryuk/nixos-config";

  # Prefer compressed RAM for routine memory pressure, then fall back to the
  # host's disk-backed swap. Keep this host-specific rather than imposing the
  # same memory policy on every machine that imports the core modules.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  # Keep both sessions available while evaluating Niri. Change this to
  # "plasma" or "niri" once a single desktop should own the host.
  desktop.session = "niri";

  # VMware's vmwgfx driver does not reliably hand the active VT from a
  # Wayland greeter to Niri, so this host renders SDDM with Xorg. XTerm is a
  # generic X server fallback and is not needed by the greeter or XWayland.
  #
  # A future physical host should omit this block and first test the common
  # Wayland SDDM default. Noctalia Greeter (on greetd) is another graphical
  # option worth evaluating once the real GPU and VT behavior are known.
  services.xserver = {
    enable = true;
    excludePackages = [ pkgs.xterm ];
  };
  services.displayManager.sddm.wayland.enable = lib.mkForce false;

  # Never change this value during a normal system upgrade.
  system.stateVersion = "26.05";
}
