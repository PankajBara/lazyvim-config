local function assert_equal(actual, expected, label)
  if not vim.deep_equal(actual, expected) then
    error(("%s\nexpected: %s\nactual:   %s"):format(label, vim.inspect(expected), vim.inspect(actual)))
  end
end

vim.opt.runtimepath:prepend(vim.uv.cwd())
local root = require("workstation.root")
local fixture = vim.fn.tempname()

local ok, err = xpcall(function()
  local function file(path, lines)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    vim.fn.writefile(lines or {}, path)
  end

  file(fixture .. "/maven/pom.xml", { "<project/>" })
  file(fixture .. "/maven/src/main/java/App.java", { "class App {}" })
  assert_equal(root.find(fixture .. "/maven/src/main/java/App.java"), fixture .. "/maven", "Maven root")

  file(fixture .. "/gradle/settings.gradle.kts", { "rootProject.name = 'fixture'" })
  file(fixture .. "/gradle/module/src/App.java", { "class App {}" })
  assert_equal(root.find(fixture .. "/gradle/module/src/App.java"), fixture .. "/gradle", "Gradle root")

  file(fixture .. "/repository/.git/HEAD", { "ref: refs/heads/main" })
  file(fixture .. "/repository/src/example.lua", { "return true" })
  assert_equal(root.lazyvim(fixture .. "/repository/src/example.lua"), { fixture .. "/repository" }, ".git directory")

  file(fixture .. "/worktree/.git", { "gitdir: ../repository/.git/worktrees/example" })
  file(fixture .. "/worktree/src/example.lua", { "return true" })
  assert_equal(root.lazyvim(fixture .. "/worktree/src/example.lua"), { fixture .. "/worktree" }, ".git file")

  file(fixture .. "/home/.git/HEAD", {})
  file(fixture .. "/home/notes/item.txt", {})
  assert_equal(root.lazyvim(fixture .. "/home/notes/item.txt", { home = fixture .. "/home" }), {}, "Home exclusion")
  assert_equal(root.lazyvim(fixture .. "/plain/file.txt"), {}, "Unmatched path")
end, debug.traceback)

vim.fn.delete(fixture, "rf")
assert(ok, err)
print("root_detection tests: ok")
