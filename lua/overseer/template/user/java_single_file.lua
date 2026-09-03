local output_dir = require("config.task_output").dir("jdtls-single")
local spring = require("spring_project")

local function source_file()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" or vim.fn.fnamemodify(path, ":e"):lower() ~= "java" then
    return nil
  end
  return vim.uv.fs_stat(path) and vim.fs.normalize(path) or nil
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
    local compile = 'javac -d "$1" "$2" && java -cp "$1" "$3"'

    cb({
      {
        name = "Java: Compile and Run File",
        builder = function()
          return {
            cmd = "sh",
            args = { "-c", compile, "java-single", output_dir, source, class },
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
