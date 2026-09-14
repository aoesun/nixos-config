local filetypes = {
  "bash",
  "json",
  "lua",
  "markdown",
  "nix",
  "vim",
  "vimdoc",
}

vim.api.nvim_create_autocmd("FileType", {
  pattern = filetypes,
  callback = function()
    pcall(vim.treesitter.start)
  end,
})
