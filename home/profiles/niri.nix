{ config, ... }:
let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in
{
  programs.noctalia = {
    enable = true;

    # Niri starts Noctalia itself, so it remains isolated from Plasma sessions.
    systemd.enable = false;

    settings = {
      shell = {
        font = "FiraCode Nerd Font";
        settings_show_advanced = true;
      };

      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Catppuccin";
      };

      wallpaper = {
        enabled = true;
        default.path = "${config.home.homeDirectory}/nixos-config/wallpaper.png";
      };

      backdrop = {
        enabled = true;
        blur_intensity = 0.5;
        tint_intensity = 0.3;
      };
    };
  };

  # Keep compositor configuration editable without rebuilding.
  xdg.configFile."niri/config.kdl" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/niri/config.kdl";
  };
}
