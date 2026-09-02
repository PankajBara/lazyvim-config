local output = require("config.task_output")
local original = vim.env.XDG_RUNTIME_DIR

vim.env.XDG_RUNTIME_DIR = "/tmp/nvim-runtime-test"
assert(
  output.dir("nvim-overseer-c") == "/tmp/nvim-runtime-test/nvim-overseer-c",
  "Task output should use XDG_RUNTIME_DIR"
)

vim.env.XDG_RUNTIME_DIR = nil
assert(
  output.dir("nvim-overseer-cpp") == vim.fs.joinpath(vim.fn.stdpath("cache"), "nvim-overseer-cpp"),
  "Task output should fall back to Neovim's cache directory"
)

vim.env.XDG_RUNTIME_DIR = original
print("task_output tests: ok")
