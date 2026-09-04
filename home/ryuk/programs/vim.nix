{ pkgs, ... }:
{
  programs.vim = {
    enable = true;
    defaultEditor = true;
    packageConfigurable = pkgs.vim;

    settings = {
      expandtab = true;
      hidden = true;
      ignorecase = true;
      number = true;
      shiftwidth = 2;
      smartcase = true;
      tabstop = 2;
    };

    extraConfig = ''
      syntax enable
      filetype plugin indent on
      set cursorline
      set incsearch
      set hlsearch
      set wildmenu
      set scrolloff=4
      set signcolumn=yes
    '';
  };
}
