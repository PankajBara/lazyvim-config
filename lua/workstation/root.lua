local M = {}

M.markers = {
  "pom.xml",
  "mvnw",
  "build.gradle",
  "build.gradle.kts",
  "settings.gradle",
  "settings.gradle.kts",
  "gradlew",
}

local function source_path(source, fallback)
  if type(source) == "number" then
    local name = vim.api.nvim_buf_get_name(source)
    source = name ~= "" and name or fallback
  end
  return source and source ~= "" and source or fallback
end

function M.find(source, opts)
  opts = opts or {}
  local fallback = opts.fallback or vim.uv.cwd()
  local path = source_path(source, fallback)
  path = vim.uv.fs_realpath(path) or vim.fs.normalize(path)
  local stat = vim.uv.fs_stat(path)
  local dir = stat and stat.type == "directory" and path or vim.fs.dirname(path)
  local home = opts.home and (vim.uv.fs_realpath(opts.home) or vim.fs.normalize(opts.home))

  while dir do
    for _, marker in ipairs(opts.markers or M.markers) do
      if vim.uv.fs_stat(vim.fs.joinpath(dir, marker)) then
        return dir
      end
    end

    local git = vim.uv.fs_stat(vim.fs.joinpath(dir, ".git"))
    if git and (git.type == "directory" or git.type == "file") and dir ~= home then
      return dir
    end

    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end
end

function M.lazyvim(source, opts)
  local root = M.find(source, opts)
  return root and { root } or {}
end

return M
