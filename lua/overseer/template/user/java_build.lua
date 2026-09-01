local spring = require("spring_project")

return {
  name = "Java/Spring build",
  generator = function(_, cb)
    local cwd = spring.root(0)
    local tasks = {}
    if not cwd then
      cb(tasks)
      return
    end
    local function add(name, cmd, args, env)
      if not cmd then
        return
      end
      tasks[#tasks + 1] = {
        name = name,
        builder = function()
          return {
            cmd = cmd,
            args = args,
            cwd = cwd,
            env = env,
            components = {
              { "open_output", on_start = "always", direction = "horizontal", focus = true },
              "default",
            },
          }
        end,
      }
    end
    local cmd = spring.command(cwd)
    local kind = spring.kind(cwd)
    if kind == "maven" then
      add("Spring Boot: Maven Run", cmd, { "spring-boot:run" }, spring.env(cwd))
      add("Maven Test", cmd, { "test" })
      add("Maven Package", cmd, { "package" })
    elseif kind == "gradle" then
      add("Spring Boot: Gradle Run", cmd, { "bootRun" }, spring.env(cwd))
      add("Gradle Test", cmd, { "test" })
      add("Gradle Build", cmd, { "build" })
    end
    cb(tasks)
  end,
  condition = {
    callback = function()
      return spring.root(0) ~= nil
    end,
  },
}
