local extensions = {
  cpp = true,
  cc = true,
  cxx = true,
}

local output_dir = "/run/user/1000/nvim-overseer-cpp"

local function source_file()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" or not extensions[vim.fn.fnamemodify(path, ":e"):lower()] then
    return nil
  end
  return vim.uv.fs_stat(path) and vim.fs.normalize(path) or nil
end

local function components()
  return {
    { "open_output", on_start = "always", direction = "horizontal", focus = true },
    { "on_output_parse", problem_matcher = "$gcc" },
    "on_result_diagnostics",
    "default",
  }
end

return {
  name = "C++ current file",
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

    local cwd = vim.fs.dirname(source)
    local executable = vim.fs.joinpath(
      output_dir,
      vim.fn.fnamemodify(source, ":t:r") .. "-" .. vim.fn.sha256(source):sub(1, 16)
    )
    local compile = 'mkdir -p "$1" && g++ -std=c++20 -Wall -Wextra -Wpedantic -g "$2" -o "$3"'

    local function task(name, command)
      return {
        name = name,
        builder = function()
          return {
            cmd = "sh",
            args = { "-c", command, "overseer-cpp", output_dir, source, executable },
            cwd = cwd,
            components = components(),
          }
        end,
      }
    end

    cb({
      task("C++: Build Current File", compile),
      task("C++: Build and Run Current File", compile .. ' && "$3"'),
    })
  end,
}
