local M = {}

local function default_context()
  return {
    version = vim.version(),
    jit = jit ~= nil,
    executable = function(name)
      return vim.fn.executable(name) == 1
    end,
    env = vim.env,
    stdpath = vim.fn.stdpath,
    fs_stat = vim.uv.fs_stat,
    open = io.open,
    config = vim.fn.stdpath("config"),
    data = vim.fn.stdpath("data"),
  }
end

local function add(results, level, message)
  results[#results + 1] = { level = level, message = message }
end

local function executable(results, ctx, name, level, label)
  if ctx.executable(name) then
    add(results, "ok", (label or name) .. " is available")
    return true
  end
  add(results, level, (label or name) .. " is not available")
  return false
end

local function writable(ctx, path)
  if not path or path == "" then
    return false
  end
  vim.fn.mkdir(path, "p")
  local probe = vim.fs.joinpath(path, ".workstation-health-" .. tostring(vim.fn.getpid()))
  local file = ctx.open(probe, "w")
  if not file then
    return false
  end
  file:close()
  vim.uv.fs_unlink(probe)
  return true
end

function M.collect(overrides)
  local ctx = vim.tbl_extend("force", default_context(), overrides or {})
  local results = {}
  local version = ctx.version
  local version_ok = version.major > 0 or version.minor > 11 or (version.minor == 11 and version.patch >= 2)
  add(results, version_ok and "ok" or "error", "Neovim 0.11.2+" .. (version_ok and "" or " is required"))
  add(results, ctx.jit and "ok" or "error", ctx.jit and "LuaJIT is enabled" or "LuaJIT is required")
  executable(results, ctx, "git", "error", "Git")
  executable(results, ctx, "rg", "error", "ripgrep")
  local compiler = ctx.executable("cc") or ctx.executable("gcc") or ctx.executable("clang")
  add(results, compiler and "ok" or "error", compiler and "A C compiler is available" or "A C compiler is required")

  executable(results, ctx, "java", "warn")
  local build_tool = ctx.executable("mvn") or ctx.executable("gradle")
  add(
    results,
    build_tool and "ok" or "warn",
    build_tool and "Maven or Gradle is available" or "Maven or Gradle is not available"
  )

  local tools = require("workstation.tools")
  local mason_packages = vim.list_extend(vim.deepcopy(tools.mason_java), tools.mason_ai)
  for _, package in ipairs(mason_packages) do
    local path = vim.fs.joinpath(ctx.data, "mason", "packages", package)
    add(
      results,
      ctx.fs_stat(path) and "ok" or "warn",
      (ctx.fs_stat(path) and "Mason package installed: " or "Mason package missing: ") .. package
    )
  end

  for _, runtime in ipairs({ "gcc", "g++", "python3", "node", "deno", "ruby", "lua" }) do
    executable(results, ctx, runtime, "info", "Optional task runtime " .. runtime)
  end
  for _, cli in ipairs({ "codex", "claude", "copilot" }) do
    executable(results, ctx, cli, "info", "Optional AI CLI " .. cli)
  end
  executable(results, ctx, "lazygit", "warn")

  local runtime = ctx.env.XDG_RUNTIME_DIR
  local cache = ctx.stdpath("cache")
  add(results, writable(ctx, cache) and "ok" or "error", "Neovim cache path is writable: " .. cache)
  if runtime and runtime ~= "" then
    add(results, writable(ctx, runtime) and "ok" or "error", "Runtime path is writable: " .. runtime)
  else
    add(results, "info", "XDG_RUNTIME_DIR is unset; task output uses the cache path")
  end

  local theme = vim.fs.joinpath(ctx.config, "lua", "plugins", "theme.lua")
  add(
    results,
    ctx.fs_stat(theme) and "ok" or "warn",
    ctx.fs_stat(theme) and "Theme configuration is available" or "Theme configuration is missing"
  )

  -- Surface Spring project detection, active profile, and resolved env source
  -- for the current buffer/working directory so Java/Spring failures are
  -- diagnosable locally without waiting for CI.
  local ok_spring, spring = pcall(require, "spring_project")
  if ok_spring and spring then
    local info
    ok_spring, info = pcall(spring.info, 0)
    if ok_spring and info then
      if info.root then
        add(results, "ok", ("Spring project detected: %s (%s)"):format(info.kind, info.root))
        add(results, "ok", "Active Spring profile: " .. info.profile)
        add(results, "info", "Resolved environment source: " .. info.env_source)
        if not info.runnable then
          add(results, "warn", info.kind .. " project detected but no executable wrapper or build tool")
        end
      else
        add(results, "info", "No Maven or Gradle project root detected for the current buffer")
      end
    end
  end

  local remote = ctx.env.TMUX or ctx.env.SSH_TTY or ctx.env.SSH_CONNECTION or ctx.env.HERDR_PANE_ID
  if remote then
    add(results, "ok", "OSC 52 clipboard support is configured for this remote session")
  else
    add(results, "info", "OSC 52 clipboard support activates in tmux, SSH, or Herdr sessions")
  end
  if ctx.env.WAYLAND_DISPLAY then
    local wayland = ctx.executable("wl-copy") and ctx.executable("wl-paste")
    add(
      results,
      wayland and "ok" or "warn",
      wayland and "Wayland clipboard tools are available" or "Wayland is active but wl-clipboard is missing"
    )
  else
    add(results, "info", "Wayland clipboard integration is not active")
  end
  return results
end

function M.check()
  vim.health.start("Workstation foundation")
  for _, result in ipairs(M.collect()) do
    vim.health[result.level](result.message)
  end
end

return M
