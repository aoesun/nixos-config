{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    jq
    tree
    wget
  ];

  programs = {
    git.enable = true;
    lazygit.enable = true;
    tmux.enable = true;

    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      configure.customRC = ''
        syntax enable
        filetype plugin indent on

        set expandtab
        set hidden
        set ignorecase
        set number
        set shiftwidth=2
        set smartcase
        set tabstop=2

        set cursorline
        set incsearch
        set hlsearch
        set wildmenu
        set scrolloff=4
        set signcolumn=yes
      '';
    };
  };
}
