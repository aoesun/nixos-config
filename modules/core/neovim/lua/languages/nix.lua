vim.lsp.config("nixd", {
  cmd = { "nixd" },
  filetypes = { "nix" },
  root_markers = { "flake.nix", ".git" },
  capabilities = require("blink.cmp").get_lsp_capabilities(),
  settings = {
    nixd = {
      nixpkgs = {
        expr = '(builtins.getFlake (toString ./.)).inputs.nixpkgs.legacyPackages.x86_64-linux',
      },
      formatting = {
        command = { "nixfmt" },
      },
      options = {
        nixos = {
          expr = '(builtins.getFlake (toString ./.)).nixosConfigurations.nixos.options',
        },
        home_manager = {
          expr = '(builtins.getFlake (toString ./.)).nixosConfigurations.nixos.options.home-manager.users.type.getSubOptions []',
        },
      },
    },
  },
})

vim.lsp.enable("nixd")
