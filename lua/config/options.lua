-- Options are automatically loaded before lazy.nvim startup.
require("config.remote_clipboard").setup()

local launch_dir = vim.uv.cwd()
local home_dir = vim.uv.fs_realpath(vim.fn.expand("~"))
local project_markers = {
  "pom.xml",
  "mvnw",
  "build.gradle",
  "build.gradle.kts",
  "settings.gradle",
  "settings.gradle.kts",
  "gradlew",
}

local function project_root(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  path = path ~= "" and (vim.uv.fs_realpath(path) or path) or launch_dir
  local stat = vim.uv.fs_stat(path)
  local dir = stat and stat.type == "directory" and path or vim.fs.dirname(path)

  while dir do
    for _, marker in ipairs(project_markers) do
      if vim.uv.fs_stat(vim.fs.joinpath(dir, marker)) then
        return { dir }
      end
    end

    local git = vim.uv.fs_stat(vim.fs.joinpath(dir, ".git"))
    if git and (git.type == "directory" or git.type == "file") and dir ~= home_dir then
      return { dir }
    end

    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end

  return {}
end

vim.g.root_spec = {
  "lsp",
  project_root,
  "lua",
  function()
    return { launch_dir }
  end,
}

vim.opt.relativenumber = false
vim.g.autoformat = false
