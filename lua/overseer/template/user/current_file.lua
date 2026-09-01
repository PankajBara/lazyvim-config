local languages = {
  c = { executable = "gcc" },
  py = { executable = "python3" },
  pyw = { executable = "python3" },
  js = { executable = "node" },
  mjs = { executable = "node" },
  cjs = { executable = "node" },
  ts = { executable = "deno" },
  mts = { executable = "deno" },
  cts = { executable = "deno" },
  rb = { executable = "ruby" },
  lua = { executable = "lua" },
}

local output_dir = "/run/user/1000/nvim-overseer-c"

local function source_file()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return nil
  end
  local extension = vim.fn.fnamemodify(path, ":e"):lower()
  local language = languages[extension]
  if not language or vim.fn.executable(language.executable) ~= 1 then
    return nil
  end
  return vim.uv.fs_stat(path) and vim.fs.normalize(path) or nil
end

local function components(problem_matcher)
  local result = {
    { "open_output", on_start = "always", direction = "horizontal", focus = true },
  }
  if problem_matcher then
    result[#result + 1] = { "on_output_parse", problem_matcher = problem_matcher }
    result[#result + 1] = "on_result_diagnostics"
  end
  result[#result + 1] = "default"
  return result
end

return {
  name = "Current file",
  condition = {
    callback = function()
      return source_file() ~= nil
    end,
  },
  generator = function(_, cb)
    local source = source_file()
    if not source then
      cb({})
      return
    end

    local extension = vim.fn.fnamemodify(source, ":e"):lower()
    local language = languages[extension]
    local cwd = vim.fs.dirname(source)
    local tasks = {}

    if extension == "c" then
      local executable = vim.fs.joinpath(
        output_dir,
        vim.fn.fnamemodify(source, ":t:r") .. "-" .. vim.fn.sha256(source):sub(1, 16)
      )
      local compile = 'mkdir -p "$1" && gcc -std=c17 -Wall -Wextra -Wpedantic -g "$2" -o "$3"'
      local function add(name, command)
        tasks[#tasks + 1] = {
          name = name,
          builder = function()
            return {
              cmd = "sh",
              args = { "-c", command, "overseer-c", output_dir, source, executable },
              cwd = cwd,
              components = components("$gcc"),
            }
          end,
        }
      end
      add("C: Build Current File", compile)
      add("C: Build and Run Current File", compile .. ' && "$3"')
    else
      local command = language.executable
      local args = { source }
      if extension == "ts" or extension == "mts" or extension == "cts" then
        args = { "run", source }
      end
      tasks[#tasks + 1] = {
        name = ({ py = "Python", pyw = "Python", js = "JavaScript", mjs = "JavaScript", cjs = "JavaScript", ts = "TypeScript", mts = "TypeScript", cts = "TypeScript", rb = "Ruby", lua = "Lua" })[extension] .. ": Run Current File",
        builder = function()
          return {
            cmd = command,
            args = args,
            cwd = cwd,
            components = components(),
          }
        end,
      }
    end

    cb(tasks)
  end,
}
