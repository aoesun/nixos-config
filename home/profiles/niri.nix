{ config, ... }:
let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in
{
  programs.noctalia = {
    enable = true;

    # Niri starts Noctalia itself, so it remains isolated from Plasma sessions.
    systemd.enable = false;
  };

  # Keep frequently edited shell settings outside the Nix store. Noctalia
  # hot-reloads this file and writes temporary GUI overrides to XDG state.
  xdg.configFile."noctalia/config.toml" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/noctalia/config.toml";
  };

  # Keep compositor configuration editable without rebuilding.
  xdg.configFile."niri/config.kdl" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/niri/config.kdl";
  };
}
