-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Cursive italics for code comments (needs a coding font with cursive italics)
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyVimStarted",
  callback = function()
    vim.api.nvim_set_hl(0, "Comment", { italic = true })
  end,
})
