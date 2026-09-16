{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.desktop;
  plasmaEnabled = builtins.elem cfg.session [
    "plasma"
    "both"
  ];
  niriEnabled = builtins.elem cfg.session [
    "niri"
    "both"
  ];

  plasmaWaylandSession = pkgs.runCommand "plasma-wayland-session" {
    passthru.providedSessions = [ "plasma" ];
  } ''
    mkdir -p "$out/share/wayland-sessions"
    ln -s ${pkgs.kdePackages.plasma-workspace.sessions}/share/wayland-sessions/plasma.desktop \
      "$out/share/wayland-sessions/plasma.desktop"
  '';
in
{
  imports = [
    ./input-method.nix
    ./niri.nix
    ./plasma.nix
  ];

  options.desktop.session = lib.mkOption {
    type = lib.types.enum [
      "plasma"
      "niri"
      "both"
    ];
    default = "plasma";
    description = "Desktop session(s) made available by the display manager.";
  };

  config = {
    fonts.packages = [ pkgs.nerd-fonts.fira-code ];

    services.displayManager = {
      # Keep one display manager regardless of the selected desktop.
      plasma-login-manager.enable = false;
      sddm = {
        enable = true;
        wayland.enable = true;
      };

      # Plasma exposes an X11 entry even when kwin-x11 is excluded, so list
      # exactly the sessions selected for this host.
      sessionPackages = lib.mkForce (
        lib.optional plasmaEnabled plasmaWaylandSession
        ++ lib.optional niriEnabled config.programs.niri.package
      );
    };
  };
}
