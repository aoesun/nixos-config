{ pkgs, ... }:
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
  environment.systemPackages = with pkgs; [
    nixd
    nixfmt
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    configure = {
      customLuaRC = ''
        require("nixos_neovim")
      '';

      packages.core.start = with pkgs.vimPlugins; [
        blink-cmp
        nvim-autopairs
        treesitter
      ];
    };

    runtime = {
      "lua/nixos_neovim/init.lua".source = ./lua/init.lua;
      "lua/nixos_neovim/options.lua".source = ./lua/options.lua;
      "lua/nixos_neovim/keymaps.lua".source = ./lua/keymaps.lua;
      "lua/nixos_neovim/completion.lua".source = ./lua/completion.lua;
      "lua/nixos_neovim/treesitter.lua".source = ./lua/treesitter.lua;
      "lua/nixos_neovim/languages/nix.lua".source = ./lua/languages/nix.lua;
    };
  };
}
