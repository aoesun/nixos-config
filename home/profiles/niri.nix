{ config, pkgs, ... }:
{
  imports = [ ../modules/dotfiles.nix ];

  # Provides the scratchpad that niri lacks; dotfiles/niri/config.kdl starts
  # niriusd and binds Mod+Grave / Mod+Shift+Grave to it.
  home.packages = [ pkgs.nirius ];

  programs.noctalia = {
    enable = true;

    # Niri starts Noctalia itself through spawn-at-startup in config.kdl.
    systemd.enable = false;
  };

  # Keep frequently edited shell settings outside the Nix store. Noctalia
  # hot-reloads this file and writes temporary GUI overrides to XDG state.
  xdg.configFile."noctalia/config.toml".source = config.lib.dotfiles.link "noctalia/config.toml";

  # Keep compositor configuration editable without rebuilding.
  xdg.configFile."niri/config.kdl".source = config.lib.dotfiles.link "niri/config.kdl";
}
