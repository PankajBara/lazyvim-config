local java_file = vim.env.JAVA_SPRING_SMOKE_FILE
if not java_file or java_file == "" then
  java_file = vim.fs.joinpath(
    vim.fn.stdpath("config"),
    "tests",
    "fixtures",
    "java",
    "src",
    "main",
    "java",
    "dev",
    "workstation",
    "App.java"
  )
end
java_file = vim.fs.normalize(java_file)
if vim.api.nvim_buf_get_name(0) ~= java_file then
  vim.cmd.edit(vim.fn.fnameescape(java_file))
end
assert(vim.bo.filetype == "java", "The current buffer must be a Java file")
assert(
  vim.wait(20000, function()
    return vim.lsp.get_clients({ bufnr = 0, name = "jdtls" })[1] ~= nil
  end, 100),
  "JDTLS did not attach"
)

assert(require("overseer"), "Overseer did not load")
assert(require("dap").adapters.java, "Java DAP adapter is not configured")
assert(#require("spring_boot").java_extensions() > 0, "Spring Java extensions did not load")

local expected = {
  [" jp"] = "Select Spring Profile",
  [" jr"] = "Run Spring Boot",
  [" jd"] = "Debug Java Main Class",
  [" ja"] = "Attach Remote JVM",
  [" tt"] = "Run All Test",
  [" tr"] = "Run Nearest Test",
  [" tT"] = "Run Test",
  [" td"] = "Debug Nearest Test",
  [" tl"] = "Rerun Last Java Test/Debug",
}
local mappings = {}
for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(0, "n")) do
  mappings[mapping.lhs] = mapping.desc
end
for lhs, desc in pairs(expected) do
  assert(mappings[lhs] == desc, ("Missing Java mapping %s (%s)"):format(lhs, desc))
end

print("java_spring smoke: ok")
