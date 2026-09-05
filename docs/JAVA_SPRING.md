# Java/Spring Neovim Workstation — Reference

## 1. What this system is

This is the Neovim configuration's **Java/Spring Boot integration layer**, built on top of
LazyVim + nvim-jdtls + spring-boot.nvim + Overseer + nvim-dap. Its job is to make editing,
running, debugging, and testing Spring Boot (Maven/Gradle) projects predictable and safe
inside Neovim — and to make the surrounding CI fail loudly and diagnosably without blocking
pull requests on flaky external Java tooling.

The system lives in four coordinated areas:

| Area | Files |
|---|---|
| Core logic | `lua/spring_project.lua` |
| Plugin wiring + commands + keymaps | `lua/plugins/java-spring.lua` |
| Build/run task templates | `lua/overseer/template/user/java_build.lua`, `java_single_file.lua` |
| Health diagnostics | `lua/workstation/health.lua` |
| CI hardening | `.github/workflows/quality.yml`, `.github/dependabot.yml`, `.github/scripts/install-java-tools.lua` |
| Tests | `tests/spring_project.lua`, `tests/health.lua`, `tests/java_spring_smoke.lua`, plus fixtures `tests/fixtures/java`, `tests/fixtures/gradle` |

---

## 2. What it does (capabilities)

### 2.1 Project detection
- Detects a project root by walking up from the current buffer/file looking for markers:
  `pom.xml`, `mvnw`, `build.gradle`, `build.gradle.kts`, `gradlew` (`M.root`).
- Classifies the build system as `"maven"` or `"gradle"` (`M.kind`).
- Skips noise directories (`.git`, `target`, `build`, `node_modules`, `generated`, etc.) so
  nested modules are discovered correctly (`ignored_dirs`, `scan_modules`).

### 2.2 Spring profile management
- Discovers available profiles by scanning `application-<name>.{properties,yml,yaml}` files
  recursively (`M.profiles`), sorting `default` first.
- Persists a selected profile per project root in a JSON state file
  (`~/.local/state/.../spring-profiles.json` by default, overridable via
  `vim.g.spring_project_state_file`).
- `M.set_profile`, `M.profile`, `M.select_profile` — selection with UI picker.

### 2.3 Environment resolution (dotenv + profile precedence)
- Parses `.env` then `.env.local`, with `.env.local` overriding `.env`.
- Injects `SPRING_PROFILES_ACTIVE` when a non-default profile is selected.
- Tracks **where each env value came from** (`M.environment` → `sources`, `source_by_key`,
  `resolved_source`) so you can see whether the profile or a dotenv file is driving the active
  Spring profile.

### 2.4 Run command resolution (`M.command`)
- Returns the project's run command: Maven wrapper `mvnw spring-boot:run` or Gradle wrapper
  `gradlew bootRun`.
- **Crucially**: only returns a wrapper if it exists **and is executable**; otherwise falls back
  to a system `mvn`/`gradle` on `PATH`; otherwise `nil`.

### 2.5 Run / Debug / Test / Attach actions
- `M.run` — launches the Spring Boot run task via Overseer.
- `M.debug_main` — JDTLS + DAP to debug the main class.
- `M.attach` — DAP remote JVM attach (host/port prompt).
- Test/debug mappings delegate to `jdtls.dap` (`test_class`, `test_nearest_method`,
  `pick_test`) with profile env injected.

### 2.6 Diagnostics & safety
- A `:SpringProjectInfo` command / `<leader>ji` keymap opens a panel (Snacks window, with a
  `vim.notify` fallback) showing root, build system, active profile, env source, and run command.
- The active Spring profile is shown in the statusline (`Spring:<profile>`) while editing a file
  inside a Maven/Gradle project, and the `<leader>j` group is labeled "Java/Spring" in which-key.
- Notifications route through Snacks when available, falling back to plain `vim.notify`.
- **Standalone Java files never start JDTLS**: a guard wraps `jdtls.start_or_attach` so JDTLS
  only attaches when a real Maven/Gradle project root exists.
- Every action that depends on JDTLS / DAP / a build tool first checks availability and shows a
  clear notification if missing (e.g. "No JDTLS client attached", "Java DAP is unavailable;
  install java-debug-adapter and java-test", "Maven project detected, but no executable wrapper
  or system build tool is available").

### 2.7 CI hardening
- Required job: formatting (`stylua --check`), all clean unit tests, an isolated bootstrap of the
  locked plugin set under isolated `XDG_*` dirs, headless startup, `git diff --check`, job
  timeout, failure-time version print, artifact upload.
- Advisory `java-integration` job (Maven **and** Gradle now): JDK 21 + JDTLS/DAP smoke test,
  `continue-on-error: true`, visible failure explanation, caches Lazy/Mason data.
- All third-party actions pinned to immutable commit SHAs; Dependabot refreshes them weekly.
- Scheduled (`cron`) + manual (`workflow_dispatch`) triggers so breakage is caught even when the
  repo is idle.

---

## 3. How it works (internals)

### 3.1 Module layout (`lua/spring_project.lua`)
- Pure-ish module returning `M`. Most functions take a `source` that is either a buffer number or
  a path; `source_path()` normalizes to a path or cwd.
- **Graceful I/O**: `read_state`, `write_state`, `load_dotenv_file` all wrap
  `io.open`/`pcall`, and `read_state` filters malformed entries so a corrupt state file degrades
  to `{}` rather than throwing.
- **`M.environment(root)`** is the single source of truth for env resolution. It returns
  `{ env, sources, source_by_key, resolved_source }`. `M.env` and `M.env_source` are thin
  accessors — this separation was added so diagnostics can show *provenance*, not just values.
- **`M.info(source)`** aggregates `root`, `kind`, `profile`, `env`, `env_sources`,
  `env_source`, `command`, `runnable` into one table consumed by both the `:SpringProjectInfo`
  command and the health check.
- **Availability guards** (`jdtls_available`, `dap_available`, `jdtls_dap_available`,
  `build_available`) return `nil` + notify instead of nil-dereferencing, so actions degrade
  gracefully.

### 3.2 Plugin wiring (`lua/plugins/java-spring.lua`)
- Augments JDTLS settings (signature help, code lenses, import ordering, lombok, etc.).
- Sets `opts.root_dir = spring_project.root` and wraps `start_or_attach` **once** (guarded by
  `jdtls._workstation_project_guard`) so standalone files can't spawn a JDTLS workspace.
- Registers buffer-local keymaps on JDTLS attach:

  | Key | Action |
  |---|---|
  | `<leader>jp` | Select Spring Profile |
  | `<leader>ji` | Inspect Java Project |
  | `<leader>jr` | Run Spring Boot |
  | `<leader>jd` | Debug Java Main Class |
  | `<leader>ja` | Attach Remote JVM |
  | `<leader>tt` | Run All Test |
  | `<leader>tr` | Run Nearest Test |
  | `<leader>tT` | Run Test |
  | `<leader>td` | Debug Nearest Test |
  | `<leader>tl` | Rerun Last Java Test/Debug |

- Test mappings check `jdtls_dap`/`dap` availability before invoking, warning if Java test support
  is missing.

### 3.3 Overseer templates
- **`java_build.lua`**: when a project root exists, offers `Spring Boot: <Maven|Gradle> Run`,
  `Test`, `Package`/`Build` tasks using `spring.command` + `spring.env`.
- **`java_single_file.lua`**: only when the current buffer is a standalone `.java` (no project
  root, `javac`+`java` on PATH) — compiles sibling `.java` files with `javac` and runs the main
  class. This is the "don't involve JDTLS" path for scratch files.

### 3.4 Health (`lua/workstation/health.lua`)
- `M.collect(ctx)` is the testable core; `M.check()` renders it via `vim.health`.
- The Spring block does `pcall(require, "spring_project")` then `pcall(spring.info, 0)`,
  reporting detection/active-profile/env-source for the current buffer, or "no root detected",
  without ever breaking the base report.

### 3.5 CI flow (`quality.yml`)
- `quality` (required): checkout → Neovim → stylua → unit tests → cache Lazy/Mason → bootstrap →
  failure diagnostics → artifact upload → `git diff --check`.
- `java-integration` (advisory): JDK 21 → Neovim → cache → bootstrap + install Java Mason tools →
  **two** smoke runs (Maven fixture, Gradle fixture via `JAVA_SPRING_SMOKE_FILE`) → failure
  explanation → artifact upload.
- Action SHAs are real, API-verified commit pins; `.github/dependabot.yml` keeps them current.

---

## 4. How to use it

### 4.1 Daily editing
1. Open a Java file inside a Maven/Gradle project. JDTLS attaches automatically (only because a
   real root was found).
2. `<leader>jp` — pick a Spring profile.
3. `<leader>jr` — run the app (Overseer task, output in a split).
4. `<leader>jd` — debug the main class; `<leader>ja` — attach to a running JVM.
5. `<leader>tt` / `tr` / `tT` / `td` — run/debug tests (env injected with the active profile).
6. `<leader>ji` (or `:SpringProjectInfo`) — opens a panel with root, build system, profile, env
   source, and run command at a glance. The statusline shows `Spring:<profile>` in Java projects.

### 4.2 Standalone scratch Java
- Open a lone `.java` (no `pom.xml`/`build.gradle` nearby) with `javac`/`java` installed →
  `<leader>rr` → "Java: Compile and Run File". JDTLS will **not** start.

### 4.3 Diagnose locally
- `:checkhealth workstation` — now shows a Spring section: detection, active profile, resolved
  environment source.
- If a run is missing: make the wrapper executable (`chmod +x mvnw`) or install Maven/Gradle on
  PATH; the action will then notify clearly if still unavailable.

### 4.4 CI / maintenance
- The required job validates formatting + unit tests + bootstrap on every push/PR.
- The Java job is advisory (`continue-on-error`); failures are visible but don't block merges.
  Re-run manually via **Actions → Quality → Run workflow** or wait for the weekly `cron`.
- Action SHAs are pinned; Dependabot opens weekly PRs to bump them. To update manually:
  `gh api repos/<owner>/<repo>/git/ref/tags/<tag>` → replace the SHA in the `uses:` line.

### 4.5 Tests / verification (run locally)
```
nvim --clean --headless -l tests/spring_project.lua   # unit: detection, profiles, env, info, overseer conditions
nvim --clean --headless -l tests/health.lua          # health collect
nvim --clean --headless -l tests/root_detection.lua
nvim --clean --headless -l tests/task_output.lua
stylua --check .
git diff --check
```
The Java smoke test (`tests/java_spring_smoke.lua`) needs the full toolchain and is exercised by
the advisory CI job (Maven + Gradle fixtures).

---

## 5. Implementation history (for context)

The hardening was completed in two rounds:

- **Round 1 (from the session plan):** fixed 6 placeholder action SHAs in `quality.yml`, added
  `.github/dependabot.yml`, documented SHA updates in README, and added regression tests for
  non-executable wrappers, malformed state, malformed/missing dotenv, and standalone files.
- **Round 2 (the four improvements):** added unit tests for `info`/`env_source`/`inspect`; added
  a Gradle fixture + second advisory CI smoke run + build-agnostic smoke assertions; added
  Overseer template-condition regression tests; added a Spring section to `:checkhealth` (with
  test coverage + README update).

All tests pass, `stylua --check .` is clean, and `git diff --check` is clean.
