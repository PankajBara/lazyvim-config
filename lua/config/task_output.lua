local M = {}

function M.dir(name)
  local base = vim.env.XDG_RUNTIME_DIR
  if not base or base == "" then
    base = vim.fn.stdpath("cache")
  end
  return vim.fs.joinpath(base, name)
end

return M
