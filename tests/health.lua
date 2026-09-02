vim.opt.runtimepath:prepend(vim.uv.cwd())
local health = require("workstation.health")
local fixture = vim.fn.tempname()
vim.fn.mkdir(fixture .. "/config/lua/plugins", "p")
vim.fn.writefile({ "return {}" }, fixture .. "/config/lua/plugins/theme.lua")

local function find(results, text)
  for _, result in ipairs(results) do
    if result.message:find(text, 1, true) then
      return result.level
    end
  end
end

local function context(executables, env, installed)
  return {
    version = { major = 0, minor = 11, patch = 2 },
    jit = true,
    executable = function(name)
      return executables[name] == true
    end,
    env = env or {},
    stdpath = function(kind)
      return fixture .. "/" .. kind
    end,
    data = fixture .. "/data",
    config = fixture .. "/config",
    fs_stat = function(path)
      if path == fixture .. "/config/lua/plugins/theme.lua" or (installed and path:find("/mason/packages/jdtls", 1, true)) then
        return { type = "file" }
      end
    end,
  }
end

local ok, err = xpcall(function()
  local results = health.collect(context({ git = true, rg = true, cc = true, java = true, mvn = true }, {}, true))
  assert(find(results, "Git is available") == "ok", "Required executable success should be healthy")
  assert(find(results, "Mason package installed: jdtls") == "ok", "Installed Mason package should be healthy")
  assert(find(results, "Optional task runtime deno") == "info", "Optional runtimes should be informational")
  assert(find(results, "XDG_RUNTIME_DIR is unset") == "info", "Unset runtime should report cache fallback")

  results = health.collect(context({}, { SSH_CONNECTION = "host", WAYLAND_DISPLAY = "wayland-1" }, false))
  assert(find(results, "Git is not available") == "error", "Missing required executable should be an error")
  assert(find(results, "Mason package missing: jdtls") == "warn", "Missing Java package should warn")
  assert(find(results, "OSC 52 clipboard support") == "ok", "Remote sessions should report OSC 52")
  assert(find(results, "Wayland is active") == "warn", "Missing Wayland clipboard tools should warn")
end, debug.traceback)

vim.fn.delete(fixture, "rf")
assert(ok, err)
print("workstation health tests: ok")
