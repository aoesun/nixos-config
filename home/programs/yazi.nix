{ config, ... }:
{
  imports = [ ../modules/dotfiles.nix ];

  programs = {
    yazi = {
      enable = true;
      enableZshIntegration = true;
      shellWrapperName = "y";
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  # Keep yazi's frequently edited config outside the Nix store.
  xdg.configFile."yazi/yazi.toml".source = config.lib.dotfiles.link "yazi/yazi.toml";
  xdg.configFile."yazi/keymap.toml".source = config.lib.dotfiles.link "yazi/keymap.toml";
}
