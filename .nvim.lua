-- Extend the generic nixd setup with options that only exist in this flake.
local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.dirname(vim.fs.normalize(source))
local flake = "(builtins.getFlake " .. string.format("%q", root) .. ")"

vim.lsp.config("nixd", {
  settings = {
    nixd = {
      options = {
        nixos = {
          expr = flake .. ".nixosConfigurations.nixos.options",
        },
        home_manager = {
          expr = flake
            .. ".nixosConfigurations.nixos.options.home-manager.users.type.getSubOptions []",
        },
      },
    },
  },
})
