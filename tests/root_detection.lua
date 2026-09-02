local function assert_equal(actual, expected, label)
  if not vim.deep_equal(actual, expected) then
    error(("%s\nexpected: %s\nactual:   %s"):format(label, vim.inspect(expected), vim.inspect(actual)))
  end
end

local fixture = vim.fn.tempname()
local worktree = fixture .. "/worktree"
local source = worktree .. "/src/example.lua"
vim.fn.mkdir(worktree .. "/src", "p")
vim.fn.writefile({ "gitdir: ../repository/.git/worktrees/example" }, worktree .. "/.git")
vim.fn.writefile({ "return true" }, source)

local root_finder = vim.g.root_spec[2]
assert(type(root_finder) == "function", "Custom project root finder is not configured")
assert_equal(root_finder(vim.fn.bufadd(source)), { worktree }, ".git file project root")

print("root_detection tests: ok")
