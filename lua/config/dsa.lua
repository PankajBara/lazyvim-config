-- DSA C++ helpers: boilerplate on new files + build/run keymaps.
-- Snippets in `snippets/cpp.json` (`main`, `fastio`, `fori`, `vpai`) cover
-- the DSA boilerplate; the previous `~/dsa/template.cpp` BufNewFile seed has
-- been removed because that path does not exist on this machine.
--
-- Build/run keymaps below delegate to the existing Overseer "C++ current
-- file" template at lua/overseer/template/user/cpp_build.lua.

local function run_cpp_task(name)
  return function()
    require("overseer").run_template({ name = name })
  end
end

vim.keymap.set("n", "<leader>rb", run_cpp_task("C++: Build Current File"),
  { desc = "DSA: Build current C++ file" })
vim.keymap.set("n", "<leader>rc", run_cpp_task("C++: Build and Run Current File"),
  { desc = "DSA: Build and run current C++ file" })
vim.keymap.set("n", "<leader>rt", run_cpp_task("C++: Build and Run with in.txt"),
  { desc = "DSA: Build and run with in.txt" })
