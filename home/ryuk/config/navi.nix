{ config, ... }:
{
  xdg.dataFile."navi/cheats/personal".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/navi";
}
