vim.lsp.config("nixd", {
  cmd = { "nixd" },
  filetypes = { "nix" },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { "flake.nix", ".git" })
      or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))

    on_dir(root)
  end,
  capabilities = require("blink.cmp").get_lsp_capabilities(),
  settings = {
    nixd = {
      formatting = {
        command = { "nixfmt" },
      },
    },
  },
})

vim.lsp.enable("nixd")
