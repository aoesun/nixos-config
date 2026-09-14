require("nixos_neovim.options")
require("nixos_neovim.keymaps")
require("nixos_neovim.completion")
require("nixos_neovim.treesitter")

require("nvim-autopairs").setup({})

require("nixos_neovim.languages.nix")
