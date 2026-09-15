{ config, ... }:
{
  programs.navi = {
    enable = true;
    enableZshIntegration = true;
  };

  xdg.dataFile."navi/cheats/personal".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/navi";
}
