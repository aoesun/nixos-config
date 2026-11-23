{
  config,
  lib,
  pkgs,
  username,
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
    ../../modules/services/mihomo.nix
    ../../modules/services/samba.nix
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
  programs.nh.flake = "${config.users.users.${username}.home}/nixos-config";

  # This host was installed with the Disko layout, whose root-blank snapshot
  # lets modules/core/impermanence.nix reset / on every boot.
  environment.persistence."/persist".enable = true;

  # Periodic TRIM is a conservative default for SSD-backed physical and
  # virtual disks.
  services.fstrim.enable = true;

  # Prefer compressed RAM for routine memory pressure, then fall back to the
  # host's disk-backed swap. Keep this host-specific rather than imposing the
  # same memory policy on every machine that imports the core modules.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  # On vmwgfx the greeter's wlroots compositor fails to close dmabuf handles
  # ("drmCloseBufferHandle failed: Invalid argument") and the greeter exits
  # with a Wayland protocol error, leaving a black screen.
  # WLR_DRM_NO_MODIFIERS=1 did not help. Rendering both sides in software
  # does: the pixman renderer does not advertise linux-dmabuf, so Mesa's
  # software EGL falls back to wl_shm. A physical host should drop this.
  services.greetd.settings.default_session.command = lib.mkForce (
    lib.escapeShellArgs [
      "${pkgs.coreutils}/bin/env"
      "WLR_RENDERER=pixman"
      "LIBGL_ALWAYS_SOFTWARE=1"
      (lib.getExe' config.services.displayManager.noctalia-greeter.package "noctalia-greeter-session")
    ]
  );

  # Never change this value during a normal system upgrade.
  system.stateVersion = "26.05";
}
