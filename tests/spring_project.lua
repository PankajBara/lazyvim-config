vim.opt.runtimepath:prepend(vim.uv.cwd())
local spring = require("spring_project")

local function assert_equal(actual, expected, label)
  if not vim.deep_equal(actual, expected) then
    error(("%s\nexpected: %s\nactual:   %s"):format(label, vim.inspect(expected), vim.inspect(actual)))
  end
end

local fixture = vim.fn.tempname()
local original_state_file = vim.g.spring_project_state_file
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
vim.fn.setfperm(fixture .. "/maven/mvnw", "rwxr-xr-x")
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
vim.fn.setfperm(fixture .. "/gradle/gradlew", "rwxr-xr-x")

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

-- Non-executable wrapper must never be returned; fall back to the system tool
-- (or nil when none is installed) rather than invoking an unexecutable file.
local non_exec = vim.fn.tempname()
vim.fn.mkdir(non_exec .. "/maven/src/main/resources", "p")
vim.fn.writefile({ "<project/>" }, non_exec .. "/maven/pom.xml")
vim.fn.writefile({ "#!/bin/sh" }, non_exec .. "/maven/mvnw")
vim.fn.setfperm(non_exec .. "/maven/mvnw", "r--r--r--")
local ne_cmd = spring.command(non_exec .. "/maven")
assert(ne_cmd ~= non_exec .. "/maven/mvnw", "Non-executable wrapper must not be used")
assert(ne_cmd == nil or vim.fn.executable(ne_cmd) == 1, "Fallback must be a system tool or nil")

-- Malformed profile state must not break profile selection.
vim.g.spring_project_state_file = fixture .. "/state/broken.json"
vim.fn.writefile({ "{ this is not valid json" }, vim.g.spring_project_state_file)
assert_equal(spring.profile(fixture .. "/maven"), "default", "Profile selection survives malformed state file")
assert_equal(
  spring.env(fixture .. "/maven").SPRING_PROFILES_ACTIVE,
  "from-dotenv",
  "Env still resolves with malformed state"
)

-- Missing and malformed dotenv files must not crash env resolution.
local dotenv_root = vim.fn.tempname()
vim.fn.mkdir(dotenv_root .. "/src/main/resources", "p")
vim.fn.writefile({ "<project/>" }, dotenv_root .. "/pom.xml")
vim.fn.setfperm(dotenv_root .. "/pom.xml", "r--r--r--")
vim.fn.writefile({ "BROKEN_LINE_NO_EQUALS" }, dotenv_root .. "/.env")
assert_equal(spring.env(dotenv_root), {}, "Malformed dotenv resolves to empty env without error")
vim.fn.delete(dotenv_root .. "/.env")
assert_equal(spring.env(dotenv_root), {}, "Missing dotenv resolves to empty env without error")

-- A standalone Java file (no project markers) must not report a root or command.
local standalone = vim.fn.tempname()
vim.fn.mkdir(standalone, "p")
local standalone_file = standalone .. "/App.java"
vim.fn.writefile({ "public class App {}" }, standalone_file)
assert_equal(spring.root(standalone_file), nil, "Standalone file has no project root")
assert_equal(spring.command(standalone), nil, "Standalone file has no build command")

-- The env_source helpers must report the driver of SPRING_PROFILES_ACTIVE.
-- The existing maven fixture has a selected "prod" profile and dotenv files,
-- so the profile should win and be reported as the resolved source.
local maven_info = spring.info(fixture .. "/maven")
assert_equal(maven_info.kind, "maven", "Info reports maven build system")
assert_equal(maven_info.profile, "prod", "Info reports active profile")
assert_equal(maven_info.env_source, "profile:prod", "Profile drives the env source")

-- env_source without a selected profile and without dotenv resolves to "none".
local bare_root = vim.fn.tempname()
vim.fn.mkdir(bare_root .. "/src/main/resources", "p")
vim.fn.writefile({ "<project/>" }, bare_root .. "/pom.xml")
vim.fn.setfperm(bare_root .. "/pom.xml", "r--r--r--")
assert_equal(spring.env_source(bare_root), "none", "No dotenv and default profile resolves to none")

-- A project with only an .env (no selected non-default profile) reports .env.
local dotenv_only = vim.fn.tempname()
vim.fn.mkdir(dotenv_only .. "/src/main/resources", "p")
vim.fn.writefile({ "<project/>" }, dotenv_only .. "/pom.xml")
vim.fn.setfperm(dotenv_only .. "/pom.xml", "r--r--r--")
vim.fn.writefile({ "TOOL=gradle" }, dotenv_only .. "/.env")
assert_equal(spring.env_source(dotenv_only), ".env", "Dotenv without profile reports .env")
vim.fn.delete(bare_root, "rf")
vim.fn.delete(dotenv_only, "rf")

-- inspect() must return the info table without throwing (it only notifies).
local inspected = spring.inspect(fixture .. "/maven")
assert(type(inspected) == "table" and inspected.root == fixture .. "/maven", "Inspect returns project info")

vim.g.spring_project_state_file = original_state_file
vim.fn.delete(fixture, "rf")
vim.fn.delete(non_exec, "rf")
vim.fn.delete(dotenv_root, "rf")
vim.fn.delete(standalone, "rf")

print("spring_project tests: ok")
