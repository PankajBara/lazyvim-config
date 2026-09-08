-- Options are automatically loaded before lazy.nvim startup.
require("config.remote_clipboard").setup()

-- Baseline: yanks/pastes reach the host/Wayland clipboard. Remote sessions
-- override vim.g.clipboard (OSC 52 / wl-clipboard) via remote_clipboard.lua.
vim.opt.clipboard = "unnamedplus"

local launch_dir = vim.uv.cwd()
local home_dir = vim.uv.fs_realpath(vim.fn.expand("~"))
local root = require("workstation.root")

vim.g.root_spec = {
  "lsp",
  function(buf)
    return root.lazyvim(buf, { fallback = launch_dir, home = home_dir })
  end,
  "lua",
  function()
    return { launch_dir }
  end,
}

vim.opt.relativenumber = false
vim.g.autoformat = false

-- Quiet, spacious defaults that make the active buffer easier to read.
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.pumheight = 12
vim.opt.showmode = false
vim.opt.cmdheight = 0
vim.opt.fillchars = {
  eob = " ",
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
}
vim.opt.listchars = {
  tab = "→ ",
  trail = "·",
  nbsp = "␣",
}
