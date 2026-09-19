{
  config,
  lib,
  pkgs,
  silentSDDM,
  ...
}:

let
  cfg = config.desktop;

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
    silentSDDM.nixosModules.default
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

    programs.silentSDDM = {
      enable = true;
      theme = "default";
    };

    # Xorg is only used to render SDDM. The selectable desktop sessions below
    # remain explicitly limited to their Wayland entries.
    services.xserver.enable = true;

    services.displayManager = {
      sddm = {
        enable = true;
        # Weston does not reliably hand the active VT over to Niri with
        # VMware's vmwgfx driver. This only changes the greeter backend;
        # every selectable desktop session remains Wayland-native.
        wayland.enable = lib.mkForce false;
      };

      # Plasma exposes an X11 entry even when kwin-x11 is excluded, so list
      # exactly the selected Wayland sessions.
      sessionPackages = lib.mkForce (
        lib.optionals (cfg.session != "niri") [ plasmaWaylandSession ]
        ++ lib.optionals (cfg.session != "plasma") [ config.programs.niri.package ]
      );
    };
  };
}
