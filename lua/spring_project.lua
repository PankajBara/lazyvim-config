local M = {}

local markers = { "pom.xml", "mvnw", "build.gradle", "build.gradle.kts", "gradlew" }
local ignored_dirs = {
  [".git"] = true,
  [".gradle"] = true,
  [".idea"] = true,
  [".mvn"] = true,
  [".settings"] = true,
  [".vscode"] = true,
  build = true,
  dist = true,
  generated = true,
  node_modules = true,
  out = true,
  target = true,
  vendor = true,
}

local function notify(message, level)
  level = level or vim.log.levels.WARN
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks and snacks.notify then
    snacks.notify(message, { title = "Spring", level = level })
    return
  end
  vim.notify(message, level, { title = "Spring" })
end

local function trim(value)
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function state_file()
  return vim.g.spring_project_state_file or (vim.fn.stdpath("state") .. "/spring-profiles.json")
end

local function read_state()
  local ok_open, file = pcall(io.open, state_file(), "r")
  if not ok_open then
    return {}
  end
  if not file then
    return {}
  end
  local ok_read, contents = pcall(file.read, file, "*a")
  pcall(file.close, file)
  if not ok_read or type(contents) ~= "string" or contents == "" then
    return {}
  end
  local ok_decode, decoded = pcall(vim.json.decode, contents)
  if not ok_decode or type(decoded) ~= "table" or vim.tbl_islist(decoded) then
    return {}
  end
  -- Ignore malformed entries rather than allowing a bad state file to break
  -- profile selection for every project.
  local state = {}
  for root, profile in pairs(decoded) do
    if type(root) == "string" and type(profile) == "string" then
      state[root] = profile
    end
  end
  return state
end

local function write_state(state)
  local path = state_file()
  pcall(vim.fn.mkdir, vim.fs.dirname(path), "p")
  local ok_open, file, err = pcall(io.open, path, "w")
  if not ok_open then
    return false
  end
  if not file then
    return false
  end
  local ok_write = pcall(file.write, file, vim.json.encode(state))
  pcall(file.close, file)
  return ok_write
end

local function source_path(source)
  if type(source) == "number" then
    local name = vim.api.nvim_buf_get_name(source)
    return name ~= "" and name or vim.uv.cwd()
  end
  return source and source ~= "" and source
    or vim.api.nvim_buf_get_name(0) ~= "" and vim.api.nvim_buf_get_name(0)
    or vim.uv.cwd()
end

function M.root(source)
  return vim.fs.root(source_path(source), markers)
end

function M.kind(root)
  if not root then
    return nil
  end
  if vim.uv.fs_stat(root .. "/pom.xml") or vim.uv.fs_stat(root .. "/mvnw") then
    return "maven"
  end
  if
    vim.uv.fs_stat(root .. "/build.gradle")
    or vim.uv.fs_stat(root .. "/build.gradle.kts")
    or vim.uv.fs_stat(root .. "/gradlew")
  then
    return "gradle"
  end
end

local function scan_resource_dir(path, found)
  local handle = vim.uv.fs_scandir(path)
  if not handle then
    return
  end
  while true do
    local name, entry_type = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if entry_type == "file" then
      local profile = name:match("^application%-(.+)%.properties$")
        or name:match("^application%-(.+)%.yml$")
        or name:match("^application%-(.+)%.yaml$")
      if profile and profile ~= "" then
        found[profile] = true
      end
    end
  end
end

local function scan_modules(path, found)
  scan_resource_dir(vim.fs.joinpath(path, "src", "main", "resources"), found)

  local handle = vim.uv.fs_scandir(path)
  if not handle then
    return
  end
  while true do
    local name, entry_type = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if entry_type == "directory" and name ~= "src" and not ignored_dirs[name] then
      scan_modules(vim.fs.joinpath(path, name), found)
    end
  end
end

function M.profiles(root)
  local found = { default = true }
  if root then
    scan_modules(root, found)
  end
  local profiles = vim.tbl_keys(found)
  table.sort(profiles, function(a, b)
    if a == b then
      return false
    end
    return a == "default" or (b ~= "default" and a < b)
  end)
  return profiles
end

function M.profile(root)
  if not root then
    return "default"
  end
  root = vim.fs.normalize(root)
  local state = read_state()
  local selected = state[root] or "default"
  if not vim.tbl_contains(M.profiles(root), selected) then
    state[root] = "default"
    write_state(state)
    return "default"
  end
  return selected
end

function M.set_profile(root, profile)
  if not root or not vim.tbl_contains(M.profiles(root), profile) then
    return false
  end
  root = vim.fs.normalize(root)
  local state = read_state()
  state[root] = profile
  return write_state(state)
end

function M.select_profile(source)
  local root = M.root(source)
  if not root then
    notify("No Maven or Gradle project root found")
    return
  end
  local profiles = M.profiles(root)
  local active = M.profile(root)
  vim.ui.select(profiles, {
    prompt = "Spring profile",
    format_item = function(item)
      return item == active and (item .. " (active)") or item
    end,
  }, function(choice)
    if choice and M.set_profile(root, choice) then
      notify("Profile set to " .. choice, vim.log.levels.INFO)
    end
  end)
end

local function quoted_value(raw, quote)
  local out, escaped = {}, false
  for index = 2, #raw do
    local char = raw:sub(index, index)
    if escaped and quote == '"' then
      local replacements = { n = "\n", r = "\r", t = "\t", ['"'] = '"', ["\\"] = "\\" }
      out[#out + 1] = replacements[char] or ("\\" .. char)
      escaped = false
    elseif char == "\\" and quote == '"' then
      escaped = true
    elseif char == quote then
      local tail = trim(raw:sub(index + 1))
      if tail == "" or tail:sub(1, 1) == "#" then
        return table.concat(out)
      end
      return nil
    else
      out[#out + 1] = char
    end
  end
  return nil
end

function M.parse_dotenv(contents)
  local env, warnings = {}, {}
  local lines = vim.split(contents or "", "\n", { plain = true })
  for line_number, original in ipairs(lines) do
    local line = trim(original:gsub("\r$", ""))
    if line ~= "" and line:sub(1, 1) ~= "#" then
      line = line:gsub("^export%s+", "")
      local key, raw = line:match("^([%a_][%w_]*)%s*=%s*(.*)$")
      local value
      if key then
        if raw:sub(1, 1) == "'" or raw:sub(1, 1) == '"' then
          value = quoted_value(raw, raw:sub(1, 1))
        else
          value = trim(raw:gsub("%s+#.*$", ""))
        end
      end
      if key and value ~= nil then
        env[key] = value
      else
        warnings[#warnings + 1] = line_number
      end
    end
  end
  return env, warnings
end

local function load_dotenv_file(path, env)
  local ok_open, file = pcall(io.open, path, "r")
  if not ok_open then
    return false
  end
  if not file then
    return false
  end
  local ok_read, contents = pcall(file.read, file, "*a")
  pcall(file.close, file)
  if not ok_read or type(contents) ~= "string" then
    return false
  end
  local parsed = M.parse_dotenv(contents)
  for key, value in pairs(parsed) do
    env[key] = value
  end
  return true
end

function M.environment(root)
  local env = {}
  local sources = {}
  local source_by_key = {}
  if root then
    for _, filename in ipairs({ ".env", ".env.local" }) do
      local path = vim.fs.joinpath(root, filename)
      local before = vim.deepcopy(env)
      if load_dotenv_file(path, env) then
        sources[#sources + 1] = filename
        for key in pairs(env) do
          if env[key] ~= before[key] then
            source_by_key[key] = filename
          end
        end
      end
    end
    local profile = M.profile(root)
    if profile ~= "default" then
      env.SPRING_PROFILES_ACTIVE = profile
      source_by_key.SPRING_PROFILES_ACTIVE = "profile:" .. profile
    end
  end
  local resolved_source = "none"
  if #sources > 0 then
    resolved_source = sources[#sources]
  end
  if source_by_key.SPRING_PROFILES_ACTIVE then
    resolved_source = source_by_key.SPRING_PROFILES_ACTIVE
  end
  return {
    env = env,
    sources = sources,
    source_by_key = source_by_key,
    resolved_source = resolved_source,
  }
end

function M.env(root)
  return M.environment(root).env
end

function M.env_source(root)
  return M.environment(root).resolved_source
end

function M.command(root)
  if not root or root == "" then
    return nil, nil
  end
  local kind = M.kind(root)
  if kind == "maven" then
    local wrapper = vim.fs.joinpath(root, "mvnw")
    local wrapper_stat = vim.uv.fs_stat(wrapper)
    if wrapper_stat and wrapper_stat.type == "file" and vim.fn.executable(wrapper) == 1 then
      return wrapper, { "spring-boot:run" }
    end
    return vim.fn.executable("mvn") == 1 and "mvn" or nil, { "spring-boot:run" }
  elseif kind == "gradle" then
    local wrapper = vim.fs.joinpath(root, "gradlew")
    local wrapper_stat = vim.uv.fs_stat(wrapper)
    if wrapper_stat and wrapper_stat.type == "file" and vim.fn.executable(wrapper) == 1 then
      return wrapper, { "bootRun" }
    end
    return vim.fn.executable("gradle") == 1 and "gradle" or nil, { "bootRun" }
  end
  return nil, nil
end

function M.info(source)
  local root = M.root(source)
  local kind = M.kind(root)
  local environment = root and M.environment(root)
    or {
      env = {},
      sources = {},
      source_by_key = {},
      resolved_source = "none",
    }
  local command = root and M.command(root) or nil
  return {
    root = root,
    kind = kind,
    profile = root and M.profile(root) or "default",
    env = environment.env,
    env_sources = environment.sources,
    env_source = environment.resolved_source,
    command = command,
    runnable = command ~= nil,
  }
end

function M.inspect(source)
  local info = M.info(source)
  local lines = {
    "Project root: " .. (info.root or "(none)"),
    "Build system: " .. (info.kind or "(none)"),
    "Spring profile: " .. info.profile,
    "Environment source: " .. info.env_source,
  }
  if info.kind and not info.runnable then
    lines[#lines + 1] = (info.kind == "maven" and "Maven" or "Gradle")
      .. " project has no executable wrapper or system build tool"
  elseif info.command then
    lines[#lines + 1] = "Run command: " .. info.command
  end
  local text = table.concat(lines, "\n")
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks and snacks.win then
    snacks.win({
      title = "Spring Project",
      text = text,
      width = 0.5,
      height = 0.4,
      border = "rounded",
      position = "center",
      relative = "editor",
      wo = { wrap = true },
    })
  else
    notify(text, vim.log.levels.INFO)
  end
  return info
end

function M.task_definition(root, name)
  local cmd, args = M.command(root)
  if not cmd then
    return nil
  end
  return {
    name = name or "Spring Boot: Run",
    cmd = cmd,
    args = args,
    cwd = root,
    env = M.env(root),
    components = {
      { "open_output", on_start = "always", direction = "horizontal", focus = true },
      "default",
    },
  }
end

function M.run(source)
  local root = M.root(source)
  if not root then
    notify("No Maven or Gradle project root found")
    return
  end
  local definition = M.task_definition(root)
  if not definition then
    local kind = M.kind(root)
    if kind then
      notify(
        (kind == "maven" and "Maven" or "Gradle")
          .. " project detected at "
          .. root
          .. ", but no executable wrapper or system build tool is available. Try `chmod +x "
          .. (kind == "maven" and "mvnw" or "gradlew")
          .. "` or install "
          .. (kind == "maven" and "Maven" or "Gradle")
          .. " on PATH."
      )
    else
      notify("No Maven or Gradle project root found")
    end
    return
  end
  require("overseer").new_task(definition):start()
end

local function jdtls_available(bufnr)
  local ok, clients = pcall(vim.lsp.get_clients, { bufnr = bufnr or 0, name = "jdtls" })
  if not ok or not clients[1] then
    notify("No JDTLS client is attached to this Java buffer")
    return false
  end
  return true
end

local function dap_available()
  local ok, dap = pcall(require, "dap")
  if not ok or type(dap) ~= "table" or type(dap.run) ~= "function" then
    notify("Java DAP is unavailable; install java-debug-adapter and java-test")
    return nil
  end
  if dap.adapters and dap.adapters.java == nil then
    notify("Java DAP adapter is unavailable; install java-debug-adapter")
    return nil
  end
  return dap
end

local function jdtls_dap_available()
  local ok, dap = pcall(require, "jdtls.dap")
  if not ok or type(dap) ~= "table" then
    notify("JDTLS Java test/debug support is unavailable; install jdtls and java-test")
    return nil
  end
  return dap
end

local build_available

function M.dap()
  return dap_available()
end

function M.jdtls_dap(bufnr)
  bufnr = bufnr or 0
  if not jdtls_available(bufnr) then
    return nil
  end
  local root = M.root(bufnr)
  if not root then
    notify("No Maven or Gradle project root found")
    return nil
  end
  if not build_available(root) then
    return nil
  end
  return jdtls_dap_available()
end

build_available = function(root)
  if M.command(root) then
    return true
  end
  local kind = M.kind(root)
  notify(
    (kind == "maven" and "Maven" or "Gradle")
      .. " project detected at "
      .. root
      .. ", but no executable wrapper or system build tool is available. Try `chmod +x "
      .. (kind == "maven" and "mvnw" or "gradlew")
      .. "` or install "
      .. (kind == "maven" and "Maven" or "Gradle")
      .. " on PATH."
  )
  return false
end

function M.debug_main(source)
  local bufnr = type(source) == "number" and source or 0
  local root = M.root(source)
  if not root then
    notify("No Maven or Gradle project root found")
    return
  end
  if not jdtls_available(bufnr) then
    return
  end
  local dap = dap_available()
  local jdtls_dap = jdtls_dap_available()
  if not dap or not jdtls_dap or not build_available(root) then
    return
  end
  jdtls_dap.fetch_main_configs({ config_overrides = { env = M.env(root) } }, function(configs)
    if #configs == 0 then
      notify("No Java main class found")
      return
    end
    table.sort(configs, function(a, b)
      return a.name < b.name
    end)
    vim.ui.select(configs, {
      prompt = "Java main class",
      format_item = function(item)
        return item.mainClass
      end,
    }, function(config)
      if config then
        dap.run(config)
      end
    end)
  end)
end

function M.attach(bufnr)
  bufnr = bufnr or 0
  if not jdtls_available(bufnr) then
    return
  end
  local dap = dap_available()
  if not dap then
    return
  end
  vim.ui.input({ prompt = "Remote JVM host: ", default = "127.0.0.1" }, function(host)
    if not host or host == "" then
      return
    end
    vim.ui.input({ prompt = "Remote JVM port: ", default = "5005" }, function(port)
      if not port or port == "" then
        return
      end
      local number = tonumber(port)
      if not number or number < 1 or number > 65535 then
        notify("Remote JVM port must be between 1 and 65535")
        return
      end
      dap.run({
        type = "java",
        request = "attach",
        name = ("Attach Java %s:%d"):format(host, number),
        hostName = host,
        port = number,
      })
    end)
  end)
end

-- Compact indicator for the statusline: the active Spring profile (or a dash
-- when no profile is selected), empty when the current buffer has no Maven or
-- Gradle project root. Guarded so it never errors outside a project.
function M.statusline()
  local ok, root = pcall(M.root, 0)
  if not ok or not root then
    return ""
  end
  local profile = M.profile(root)
  return " Spring:" .. (profile == "default" and "—" or profile)
end

return M
