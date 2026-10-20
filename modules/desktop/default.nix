{
  config,
  lib,
  pkgs,
  silentSDDM,
  ...
}:

let
  cfg = config.desktop;

  plasmaWaylandSession =
    pkgs.runCommand "plasma-wayland-session"
      {
        passthru.providedSessions = [ "plasma" ];
      }
      ''
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
    fonts = {
      packages = with pkgs; [
        # Keep Fira Code until Noctalia stops referencing it.
        maple-mono.NF-CN
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
      ];

      # Han characters resolve to Simplified Chinese glyphs first, so the
      # en_US locale does not pick Japanese variants.
      fontconfig.defaultFonts = {
        monospace = [
          "Maple Mono NF CN"
          "Noto Sans Mono CJK SC"
        ];
        sansSerif = [ "Noto Sans CJK SC" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };

    programs.localsend = {
      enable = true;
      openFirewall = false;
    };

    programs.silentSDDM = {
      enable = true;
      theme = "default";
    };

    services.displayManager = {
      sddm = {
        enable = true;
        # Prefer a Wayland-native greeter. Hosts with incompatible graphics
        # may override this without changing the desktop sessions themselves.
        wayland.enable = true;
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
