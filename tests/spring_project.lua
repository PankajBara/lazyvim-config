local spring = require("spring_project")

local function assert_equal(actual, expected, label)
  if not vim.deep_equal(actual, expected) then
    error(("%s\nexpected: %s\nactual:   %s"):format(label, vim.inspect(expected), vim.inspect(actual)))
  end
end

local fixture = vim.fn.tempname()
vim.fn.mkdir(fixture .. "/maven/src/main/resources", "p")
vim.fn.mkdir(fixture .. "/maven/modules/accounts/src/main/resources", "p")
vim.fn.mkdir(fixture .. "/maven/target/generated/src/main/resources", "p")
vim.fn.mkdir(fixture .. "/maven/build/src/main/resources", "p")
vim.fn.mkdir(fixture .. "/maven/generated/src/main/resources", "p")
vim.fn.mkdir(fixture .. "/maven/node_modules/example/src/main/resources", "p")
vim.fn.mkdir(fixture .. "/maven/src/test/resources", "p")
vim.fn.mkdir(fixture .. "/gradle/src/main/resources", "p")
vim.fn.writefile({ "<project/>" }, fixture .. "/maven/pom.xml")
vim.fn.writefile({ "#!/bin/sh" }, fixture .. "/maven/mvnw")
vim.fn.writefile({}, fixture .. "/maven/src/main/resources/application-dev.properties")
vim.fn.writefile({}, fixture .. "/maven/src/main/resources/application-prod.yml")
vim.fn.writefile({}, fixture .. "/maven/src/main/resources/application-qa.yaml")
vim.fn.writefile({}, fixture .. "/maven/modules/accounts/src/main/resources/application-alpha.yml")
vim.fn.writefile({}, fixture .. "/maven/target/generated/src/main/resources/application-generated.yml")
vim.fn.writefile({}, fixture .. "/maven/build/src/main/resources/application-build.yml")
vim.fn.writefile({}, fixture .. "/maven/generated/src/main/resources/application-generated-root.yml")
vim.fn.writefile({}, fixture .. "/maven/node_modules/example/src/main/resources/application-dependency.yml")
vim.fn.writefile({}, fixture .. "/maven/src/test/resources/application-test.yml")
vim.fn.writefile({}, fixture .. "/maven/application-unconventional.yml")
vim.fn.writefile({ "plugins {}" }, fixture .. "/gradle/build.gradle.kts")
vim.fn.writefile({ "#!/bin/sh" }, fixture .. "/gradle/gradlew")

assert_equal(
  spring.root(fixture .. "/maven/src/main/resources/application-dev.properties"),
  fixture .. "/maven",
  "Maven root"
)
assert_equal(spring.root(fixture .. "/gradle/src/main/resources"), fixture .. "/gradle", "Gradle root")
assert_equal(
  spring.profiles(fixture .. "/maven"),
  { "default", "alpha", "dev", "prod", "qa" },
  "Nested profile discovery, ordering, and directory pruning"
)

local maven_cmd, maven_args = spring.command(fixture .. "/maven")
assert_equal(maven_cmd, fixture .. "/maven/mvnw", "Maven wrapper")
assert_equal(maven_args, { "spring-boot:run" }, "Maven run arguments")
local gradle_cmd, gradle_args = spring.command(fixture .. "/gradle")
assert_equal(gradle_cmd, fixture .. "/gradle/gradlew", "Gradle wrapper")
assert_equal(gradle_args, { "bootRun" }, "Gradle run arguments")

local parsed, warnings = spring.parse_dotenv([[
# comment
export PLAIN=value
SPACED=hello world # comment
SINGLE='literal # value'
DOUBLE="line\nvalue"
EMPTY=
BROKEN
]])
assert_equal(parsed, {
  PLAIN = "value",
  SPACED = "hello world",
  SINGLE = "literal # value",
  DOUBLE = "line\nvalue",
  EMPTY = "",
}, "Dotenv parsing")
assert_equal(warnings, { 7 }, "Malformed dotenv warning")

vim.g.spring_project_state_file = fixture .. "/state/profiles.json"
vim.fn.writefile({ "BASE=base", "OVERRIDE=old", "SPRING_PROFILES_ACTIVE=from-dotenv" }, fixture .. "/maven/.env")
vim.fn.writefile({ "OVERRIDE=local", "LOCAL=yes" }, fixture .. "/maven/.env.local")
assert(spring.set_profile(fixture .. "/maven", "prod"), "Profile should persist")
assert_equal(spring.env(fixture .. "/maven"), {
  BASE = "base",
  OVERRIDE = "local",
  LOCAL = "yes",
  SPRING_PROFILES_ACTIVE = "prod",
}, "Dotenv precedence and selected profile")

vim.fn.writefile({}, fixture .. "/maven/src/main/resources/application-prod.yml")
vim.uv.fs_unlink(fixture .. "/maven/src/main/resources/application-prod.yml")
assert_equal(spring.profile(fixture .. "/maven"), "default", "Stale profile fallback")
assert_equal(spring.env(fixture .. "/maven").SPRING_PROFILES_ACTIVE, "from-dotenv", "Default keeps dotenv profile")

local state = table.concat(vim.fn.readfile(vim.g.spring_project_state_file), "\n")
assert(
  not state:find("base", 1, true) and not state:find("local", 1, true),
  "State must not contain environment values"
)

print("spring_project tests: ok")
