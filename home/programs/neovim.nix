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
  imports = [ ../modules/dotfiles.nix ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    initLua = ''
      dofile("${config.dotfiles.path}/nvim/init.lua")
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
  xdg.configFile."nvim/lua".source = config.lib.dotfiles.link "nvim/lua";
}
