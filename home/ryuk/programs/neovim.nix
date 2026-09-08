{ ... }:
{
  # Keep Vim as the default editor while learning Neovim.
  programs.neovim = {
    enable = true;
    defaultEditor = false;
    viAlias = false;
    vimAlias = false;
    vimdiffAlias = false;
  };
}
