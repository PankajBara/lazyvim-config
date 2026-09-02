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
  vim.notify(message, level or vim.log.levels.WARN, { title = "Spring" })
end

local function trim(value)
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function state_file()
  return vim.g.spring_project_state_file or (vim.fn.stdpath("state") .. "/spring-profiles.json")
end

local function read_state()
  local file = io.open(state_file(), "r")
  if not file then
    return {}
  end
  local contents = file:read("*a")
  file:close()
  local ok, decoded = pcall(vim.json.decode, contents)
  return ok and type(decoded) == "table" and decoded or {}
end

local function write_state(state)
  local path = state_file()
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local file, err = io.open(path, "w")
  if not file then
    notify("Could not save the selected profile: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end
  file:write(vim.json.encode(state))
  file:close()
  return true
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
  local file = io.open(path, "r")
  if not file then
    return
  end
  local parsed, warnings = M.parse_dotenv(file:read("*a"))
  file:close()
  for key, value in pairs(parsed) do
    env[key] = value
  end
  for _, line_number in ipairs(warnings) do
    notify(("Ignoring malformed dotenv assignment in %s at line %d"):format(vim.fs.basename(path), line_number))
  end
end

function M.env(root)
  local env = {}
  if root then
    load_dotenv_file(root .. "/.env", env)
    load_dotenv_file(root .. "/.env.local", env)
    local profile = M.profile(root)
    if profile ~= "default" then
      env.SPRING_PROFILES_ACTIVE = profile
    end
  end
  return env
end

function M.command(root)
  local kind = M.kind(root)
  if kind == "maven" then
    local wrapper = root .. "/mvnw"
    return vim.uv.fs_stat(wrapper) and wrapper or vim.fn.executable("mvn") == 1 and "mvn" or nil, { "spring-boot:run" }
  elseif kind == "gradle" then
    local wrapper = root .. "/gradlew"
    return vim.uv.fs_stat(wrapper) and wrapper or vim.fn.executable("gradle") == 1 and "gradle" or nil, { "bootRun" }
  end
  return nil, nil
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
    notify("No runnable Spring Boot task found (wrapper or build tool missing)")
    return
  end
  require("overseer").new_task(definition):start()
end

local function jdtls_available(bufnr)
  if not vim.lsp.get_clients({ bufnr = bufnr or 0, name = "jdtls" })[1] then
    notify("No JDTLS client is attached to this Java buffer")
    return false
  end
  return true
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
  require("jdtls.dap").fetch_main_configs({ config_overrides = { env = M.env(root) } }, function(configs)
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
        require("dap").run(config)
      end
    end)
  end)
end

function M.attach(bufnr)
  bufnr = bufnr or 0
  if not jdtls_available(bufnr) then
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
      require("dap").run({
        type = "java",
        request = "attach",
        name = ("Attach Java %s:%d"):format(host, number),
        hostName = host,
        port = number,
      })
    end)
  end)
end

return M
