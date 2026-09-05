local output_dir = require("config.task_output").dir("jdtls-single")
local spring = require("spring_project")

local function source_file()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" or vim.fn.fnamemodify(path, ":e"):lower() ~= "java" then
    return nil
  end
  return vim.uv.fs_stat(path) and vim.fs.normalize(path) or nil
end

local function sibling_sources(directory)
  local sources = {}
  local handle = vim.uv.fs_scandir(directory)
  if not handle then
    return sources
  end

  while true do
    local name = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if vim.fn.fnamemodify(name, ":e"):lower() == "java" then
      local path = vim.fs.normalize(vim.fs.joinpath(directory, name))
      local stat = vim.uv.fs_stat(path)
      if stat and stat.type == "file" then
        sources[#sources + 1] = path
      end
    end
  end

  table.sort(sources)
  return sources
end

local function package_name(source)
  local file = io.open(source, "r")
  if not file then
    return nil
  end

  for line in file:lines() do
    local package = line:match("^%s*package%s+([%a_$][%w_$%.]*)%s*;")
    if package then
      file:close()
      return package
    end
  end

  file:close()
  return nil
end

return {
  name = "Java single file",
  -- Only offer this for standalone files: there is no Maven/Gradle project root,
  -- otherwise the project-aware Spring tasks are the right choice.
  condition = {
    callback = function()
      return source_file() ~= nil
        and vim.fn.executable("javac") == 1
        and vim.fn.executable("java") == 1
        and spring.root(0) == nil
    end,
  },
  generator = function(_, cb)
    local source = source_file()
    if not source then
      cb({})
      return
    end

    local cwd = vim.fs.dirname(source)
    local class = vim.fn.fnamemodify(source, ":t:r")
    local package = package_name(source)
    local main_class = package and (package .. "." .. class) or class
    local sources = sibling_sources(cwd)
    if not vim.tbl_contains(sources, source) then
      sources[#sources + 1] = source
      table.sort(sources)
    end
    local quoted_sources = {}
    for _, path in ipairs(sources) do
      quoted_sources[#quoted_sources + 1] = vim.fn.shellescape(path)
    end
    local compile = ('mkdir -p "$1" && javac -d "$1" %s && java -cp "$1" %s'):format(
      table.concat(quoted_sources, " "),
      vim.fn.shellescape(main_class)
    )

    cb({
      {
        name = "Java: Compile and Run File",
        builder = function()
          return {
            cmd = "sh",
            args = { "-c", compile, "java-single", output_dir },
            cwd = cwd,
            components = {
              { "open_output", on_start = "always", direction = "horizontal", focus = true },
              "default",
            },
          }
        end,
      },
    })
  end,
}
