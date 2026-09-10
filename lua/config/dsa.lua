-- DSA C++ helpers: boilerplate on new files + build/run keymaps.
-- Relies on the existing Overseer "C++ current file" template
-- (lua/overseer/template/user/cpp_build.lua).

local template = vim.fn.stdpath("config") .. "/../dsa/template.cpp"
local template_path = vim.fs.normalize(vim.fn.expand("~/dsa/template.cpp"))
if vim.uv.fs_stat(template_path) then
  template = template_path
end

-- Seed new, empty .cpp files with the DSA boilerplate.
vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = "*.cpp",
  group = vim.api.nvim_create_augroup("dsa-boilerplate", { clear = true }),
  callback = function()
    if vim.fn.line("$") == 1 and vim.fn.getline(1) == "" then
      local ok, lines = pcall(vim.fn.readfile, template)
      if ok and #lines > 0 then
        vim.api.nvim_put(lines, "l", false, true)
        vim.cmd("silent! write")
      end
    end
  end,
})

local function run_cpp_task(name)
  return function()
    local overseer = require("overseer")
    local tasks = overseer.list_tasks({ recent_first = true })
    for _, t in ipairs(tasks) do
      if t.name == name then
        t:restart()
        return
      end
    end
    overseer.run_template({ name = name }, function(task)
      if task then
        task:start()
      end
    end)
  end
end

vim.keymap.set("n", "<leader>rb", run_cpp_task("C++: Build Current File"),
  { desc = "DSA: Build current C++ file" })
vim.keymap.set("n", "<leader>rc", run_cpp_task("C++: Build and Run Current File"),
  { desc = "DSA: Build and run current C++ file" })
