{ config, pkgs, ... }:
let
  treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (
    grammars: with grammars; [
      bash
      json
      lua
      markdown
      markdown_inline
      nix
      vim
      vimdoc
    ]
  );
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    initLua = ''
      dofile("${config.home.homeDirectory}/dotfiles/nvim/init.lua")
    '';

    extraPackages = with pkgs; [
      nixd
      nixfmt
    ];

    plugins = with pkgs.vimPlugins; [
      blink-cmp
      nvim-autopairs
      treesitter
    ];
  };

  # Keep frequently edited Lua in the dotfiles repository while Home Manager
  # remains responsible for Neovim and all of its runtime dependencies.
  xdg.configFile."nvim/lua".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/nvim/lua";
}
