local function root()
  return vim.fs.root(0, { "pom.xml", "mvnw", "build.gradle", "build.gradle.kts", "gradlew" }) or vim.uv.cwd()
end

local function executable(kind, cwd)
  local wrapper = kind == "maven" and "mvnw" or "gradlew"
  local fallback = kind == "maven" and "mvn" or "gradle"
  return vim.fn.executable(cwd .. "/" .. wrapper) == 1 and (cwd .. "/" .. wrapper) or fallback
end

return {
  name = "Java/Spring build",
  generator = function(_, cb)
    local cwd = root()
    local tasks = {}
    local function add(name, kind, arg)
      tasks[#tasks + 1] = {
        name = name,
        builder = function()
          return {
            cmd = executable(kind, cwd),
            args = { arg },
            cwd = cwd,
            components = {
              { "open_output", on_start = "always", direction = "horizontal", focus = true },
              "default",
            },
          }
        end,
      }
    end
    if vim.uv.fs_stat(cwd .. "/pom.xml") then
      add("Spring Boot: Maven Run", "maven", "spring-boot:run")
      add("Maven Test", "maven", "test")
      add("Maven Package", "maven", "package")
    end
    if vim.uv.fs_stat(cwd .. "/build.gradle") or vim.uv.fs_stat(cwd .. "/build.gradle.kts") then
      add("Spring Boot: Gradle Run", "gradle", "bootRun")
      add("Gradle Test", "gradle", "test")
      add("Gradle Build", "gradle", "build")
    end
    cb(tasks)
  end,
  condition = { callback = function() return vim.uv.fs_stat(root() .. "/pom.xml") ~= nil
    or vim.uv.fs_stat(root() .. "/build.gradle") ~= nil
    or vim.uv.fs_stat(root() .. "/build.gradle.kts") ~= nil end },
}
