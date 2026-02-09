-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "*" },
  callback = function()
    vim.b.autoformat = true

    local file_name = vim.api.nvim_buf_get_name(0)
    if file_name:match("%.env%") then
      vim.diagnostic.enable(false)
    end
  end,
})
