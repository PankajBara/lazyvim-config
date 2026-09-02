local names = require("workstation.tools").mason_java
local registry = require("mason-registry")
local done, failure = false, nil

registry.refresh(function(success, err)
  if not success then
    failure = err or "Mason registry refresh failed"
    done = true
    return
  end
  for _, name in ipairs(names) do
    local package = registry.get_package(name)
    if not package:is_installed() and not package:is_installing() then
      package:install()
    end
  end
  done = true
end)

assert(vim.wait(120000, function()
  return done
end, 100), "Timed out refreshing the Mason registry")
assert(not failure, failure)
assert(vim.wait(600000, function()
  for _, name in ipairs(names) do
    local package = registry.get_package(name)
    if not package:is_installed() then
      return false
    end
  end
  return true
end, 500), "Timed out installing Java Mason packages")

print("Java Mason packages: ok")
