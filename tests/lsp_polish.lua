vim.opt.runtimepath:prepend(vim.uv.cwd())
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local function load(path)
  local full = vim.fs.joinpath(vim.fn.stdpath("config"), path)
  assert(vim.fn.filereadable(full) == 1, ("missing %s"):format(full))
  local chunk, err = loadfile(full)
  assert(chunk, err)
  chunk()
end

load("lua/config/options.lua")
load("lua/config/keymaps.lua")
load("lua/plugins/lsp-polish.lua")
local neo_tree_spec = loadfile(vim.fs.joinpath(vim.fn.stdpath("config"), "lua/plugins/neo-tree.lua"))()
local neo_tree_opts = neo_tree_spec[1].opts({}, {})
assert(neo_tree_opts.filesystem.window.mappings["/"] == "fuzzy_finder_directory", "Neo-tree / must search directories")
assert(neo_tree_opts.filesystem.window.mappings.D == "fuzzy_finder_directory", "Neo-tree D must search directories")
-- The lsp-polish file exposes its autocmd helper via
-- `package.loaded["workstation.lsp_polish"]` so headless tests can trigger
-- the same LspAttach registration that lazy.nvim's `init` callback wires up.
local polish = require("workstation.lsp_polish")
assert(
  type(polish.setup_inlay_hints_on_attach) == "function",
  "workstation.lsp_polish.setup_inlay_hints_on_attach must be exposed"
)
polish.setup_inlay_hints_on_attach()

local function expand_leader(s)
  local leader = vim.g.mapleader or "\\"
  return (s:gsub("<leader>", leader):gsub("<localleader>", vim.g.maplocalleader or "\\"))
end

local function has_map(mode, lhs)
  local target = expand_leader(lhs)
  for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
    if m.lhs == target then
      return true
    end
  end
  return false
end

assert(has_map("n", "<leader>j"), "<leader>j (Flash Jump) must be mapped in normal mode")
assert(has_map("n", "<leader>J"), "<leader>J (Flash Jump Forward) must be mapped in normal mode")
assert(has_map("n", "<leader>cl"), "<leader>cl (CodeLens Refresh) must be mapped in normal mode")
assert(has_map("n", "<leader>cL"), "<leader>cL (CodeLens Run) must be mapped in normal mode")

assert(vim.fn.maparg(expand_leader("<leader>j"), "n") ~= "", "<leader>j must resolve to a keymap")
assert(vim.fn.maparg(expand_leader("<leader>cl"), "n") ~= "", "<leader>cl must resolve to a keymap")

assert(vim.opt.undofile:get() == true, "vim.opt.undofile must be enabled")
local undodir_list = vim.opt.undodir:get()
local undodir = type(undodir_list) == "table" and undodir_list[1] or undodir_list
assert(
  type(undodir) == "string" and undodir ~= "",
  ("vim.opt.undodir must be set (got %s)"):format(vim.inspect(undodir_list))
)
assert(vim.fn.isdirectory(undodir) == 1, ("undodir must exist: %s"):format(undodir))

local seen_group = false
for _, name in ipairs(vim.api.nvim_get_autocmds({ event = "LspAttach" })) do
  if name.group_name == "WorkstationInlayHints" then
    seen_group = true
    break
  end
end
assert(seen_group, "LspAttach autocmd group WorkstationInlayHints must be registered")

assert(type(vim.lsp.inlay_hint) == "table", "vim.lsp.inlay_hint must be available (Neovim 0.10+)")

print("lsp_polish smoke: ok")
