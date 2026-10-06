-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("i", "jj", "<Esc>", { silent = true })

vim.keymap.set({ "n", "x", "o" }, "<leader>j", function()
  require("flash").jump()
end, { desc = "Flash Jump" })

vim.keymap.set({ "n", "x", "o" }, "<leader>J", function()
  require("flash").jump({ forward = true, label = { after = false } })
end, { desc = "Flash Jump Forward" })

local function ts_select(lhs, query, desc)
  vim.keymap.set("x", lhs, ("<cmd> TSTextobject %s<cr>"):format(query), { silent = true, desc = desc })
end
ts_select("<localleader>f", "function", "Function Outer")
ts_select("<localleader>F", "function.inner", "Function Inner")
ts_select("<localleader>c", "class", "Class Outer")
ts_select("<localleader>C", "class.inner", "Class Inner")
ts_select("<localleader>p", "parameter", "Parameter Outer")
ts_select("<localleader>P", "parameter.inner", "Parameter Inner")
ts_select("<localleader>a", "block", "Block Outer")
ts_select("<localleader>A", "block.inner", "Block Inner")

vim.keymap.set("n", "<leader>cl", function()
  vim.lsp.codelens.refresh()
end, { desc = "CodeLens Refresh" })

vim.keymap.set("n", "<leader>cL", function()
  vim.lsp.codelens.run()
end, { desc = "CodeLens Run" })

local codelens_refresh_timers = {}
local function refresh_codelens(args)
  local bufnr = args.buf
  if codelens_refresh_timers[bufnr] then
    codelens_refresh_timers[bufnr]:stop()
  end
  codelens_refresh_timers[bufnr] = vim.defer_fn(function()
    codelens_refresh_timers[bufnr] = nil
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    for _, client in ipairs(clients) do
      if client.server_capabilities.codeLensProvider then
        pcall(vim.lsp.codelens.refresh, { bufnr = bufnr })
        return
      end
    end
  end, 250)
end

vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "BufWritePost" }, {
  group = vim.api.nvim_create_augroup("WorkstationCodeLensAuto", { clear = true }),
  callback = refresh_codelens,
})

vim.api.nvim_create_autocmd("BufDelete", {
  group = vim.api.nvim_create_augroup("WorkstationCodeLensCleanup", { clear = true }),
  callback = function(args)
    local timer = codelens_refresh_timers[args.buf]
    if timer then
      timer:stop()
      codelens_refresh_timers[args.buf] = nil
    end
  end,
})
