{ ... }:
{
  imports = [
    ./programs/neovim.nix
    ./programs/tools.nix
    ./programs/vim.nix
    ./programs/yazi.nix
    ./programs/zsh.nix
  ];

  home = {
    username = "ryuk";
    homeDirectory = "/home/ryuk";
    stateVersion = "26.05";
  };

  xdg.enable = true;
  programs.home-manager.enable = true;
}
