local java_file = vim.env.JAVA_SPRING_SMOKE_FILE
assert(java_file and java_file ~= "", "JAVA_SPRING_SMOKE_FILE is required")

vim.cmd.edit(vim.fn.fnameescape(java_file))
assert(
  vim.wait(20000, function()
    return vim.lsp.get_clients({ bufnr = 0, name = "jdtls" })[1] ~= nil
  end, 100),
  "JDTLS did not attach"
)

assert(require("overseer"), "Overseer did not load")
assert(require("dap").adapters.java, "Java DAP adapter is not configured")

local expected = {
  ["<Space>jp"] = "Select Spring Profile",
  ["<Space>jr"] = "Run Spring Boot",
  ["<Space>jd"] = "Debug Java Main Class",
  ["<Space>ja"] = "Attach Remote JVM",
  ["<Space>tt"] = "Run All Test",
  ["<Space>tr"] = "Run Nearest Test",
  ["<Space>tT"] = "Run Test",
  ["<Space>td"] = "Debug Nearest Test",
  ["<Space>tl"] = "Rerun Last Java Test/Debug",
}
local mappings = {}
for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(0, "n")) do
  mappings[mapping.lhs] = mapping.desc
end
for lhs, desc in pairs(expected) do
  assert(mappings[lhs] == desc, ("Missing Java mapping %s (%s)"):format(lhs, desc))
end

print("java_spring smoke: ok")
