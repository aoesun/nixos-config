{ config, ... }:
{
  imports = [ ../modules/dotfiles.nix ];

  programs.navi = {
    enable = true;
    enableZshIntegration = true;
  };

  xdg.dataFile."navi/cheats/personal".source = config.lib.dotfiles.link "navi";
}
