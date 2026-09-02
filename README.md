# Neovim development configuration

A [LazyVim](https://www.lazyvim.org/)-based Neovim setup for general Linux development. It includes language tooling, completion, debugging, testing, REST requests, project tasks, Git integration, a file tree, and optional AI command-line agents. Omarchy theme synchronization and remote clipboard support are optional enhancements; the configuration works without Omarchy.

Automatic formatting is disabled globally. Use the manual formatting mapping when wanted. Java imports are still organized automatically before each Java file is saved.

## Requirements

- Neovim 0.11.2 or newer, built with LuaJIT
- Git, [ripgrep](https://github.com/BurntSushi/ripgrep), and a C compiler
- Internet access on the first launch
- Optional: a [Nerd Font](https://www.nerdfonts.com/) for complete icons

Install only the tools needed for your work: `lazygit` for the Git UI; `wl-clipboard` for Wayland clipboard integration; language runtimes; a JDK and Maven/Gradle; and `codex`, `claude`, or `copilot` for AI CLI sessions. Language servers, debuggers, and formatters managed by Mason can be installed from `:Mason`.

## Installation and updates

Back up an existing configuration first:

```sh
mv ~/.config/nvim ~/.config/nvim.backup-$(date +%Y%m%d-%H%M%S)
git clone https://github.com/PankajBara/lazyvim-config.git ~/.config/nvim
nvim
```

On the first launch, lazy.nvim installs the pinned plugins and Mason begins installing configured Java tools. Let installation finish, restart Neovim, then run `:checkhealth workstation`. Existing data under `~/.local/share/nvim` is not removed by these commands.

To update later:

```sh
git -C ~/.config/nvim pull --ff-only
```

Then open `:Lazy`, press `S` to sync plugins, and review changes before committing local customizations. Use `:Mason` to update external language tools. The lockfile keeps plugin versions reproducible.

## Workstation health

Run `:checkhealth workstation` after installation or when a tool-backed feature stops working. The report checks:

- Neovim 0.11.2+, LuaJIT, Git, ripgrep, and a C compiler
- Java, Maven/Gradle, and the configured Mason Java and Copilot packages
- task runtimes, AI CLIs, lazygit, and context-appropriate clipboard tools
- writable runtime/cache directories and the generated or fallback theme configuration
- OSC 52 support in tmux, SSH, and Herdr sessions, plus Wayland clipboard support when Wayland is active

Missing baseline requirements and unwritable required paths are errors. Missing Java workstation dependencies, Mason packages, lazygit, or active Wayland clipboard tools are warnings. Runtimes and AI CLIs used only by optional tasks are informational.

## What is enabled

- C/C++ (clangd), Java/JDTLS and Spring Boot, JSON, SQL, YAML, Lua, plus LazyVim's core LSP and completion support
- nvim-dap, DAP UI, Java debugging and remote attach; Neotest and Java test actions
- Kulala REST requests, Overseer tasks, Neo-tree, Snacks search, Trouble, and Git signs
- Copilot language-server suggestions and Sidekick sessions for installed Codex, Claude, or Copilot CLIs
- Multiple colorschemes, transparent highlights, optional Omarchy theme reload, and optional OSC 52/tmux/Wayland clipboard handling

Configured extras are recorded in [`lazyvim.json`](lazyvim.json); plugin versions are pinned in [`lazy-lock.json`](lazy-lock.json).

## Keymaps

`<leader>` is Space. Press Space and pause to open which-key. Because upstream LazyVim bindings can change, `<leader>sk` is the authoritative searchable list of active mappings.

### Custom mappings

Java mappings are buffer-local and appear after JDTLS attaches.

| Mapping | Action |
| --- | --- |
| `<leader>rr` | Choose a project or current-file Overseer task |
| `<leader>jp` | Select and persist a Spring profile |
| `<leader>jr` | Run the Spring Boot application |
| `<leader>jd` | Select and debug a Java main class |
| `<leader>ja` | Attach the debugger to a remote JVM |
| `<leader>tt` | Run the current Java test class |
| `<leader>tr` | Run the nearest Java test method |
| `<leader>tT` | Pick a Java test to run |
| `<leader>td` | Debug the nearest Java test method |
| `<leader>tl` | Rerun the last Java test or debug session |
| `<leader>as` | Select an installed Codex, Claude, or Copilot CLI |

The Java test mappings override equivalent Neotest mappings only in Java buffers.

### Essential LazyVim mappings

This compact list matches the pinned LazyVim version. It is intentionally not exhaustive.

| Area | Mappings |
| --- | --- |
| Files | `<leader>ff` project files, `<leader>fF` cwd files, `<leader>e` project tree |
| Search | `<leader>sg` live grep, `<leader>sw` word/selection, `<leader>sb` buffer lines, `<leader>sk` keymaps |
| Buffers | `<leader>,` picker, `<leader>bb` alternate buffer, `<leader>bd` delete buffer |
| Windows | `<C-h/j/k/l>` move, `<leader>wd` close, `<leader>wm` zoom |
| LSP | `gd` definition, `gr` references, `K` hover, `<leader>ca` code action, `<leader>cr` rename |
| Diagnostics | `[d`/`]d` previous/next, `<leader>cd` details, `<leader>xx` Trouble |
| Formatting | `<leader>cf` format; `<leader>uf` toggles autoformat |
| Git | `<leader>gg` lazygit, `<leader>ghp` preview hunk, `<leader>ghs` stage hunk |
| Terminal | `<leader>ft` project terminal, `<leader>fT` cwd terminal |
| Testing | `<leader>tt` file, `<leader>tr` nearest, `<leader>ts` summary outside Java overrides |
| Debugging | `<leader>db` breakpoint, `<leader>dc` continue, `<leader>du` UI, `<leader>dt` terminate |
| Plugins/tools | `<leader>l` Lazy, `<leader>cm` Mason |

## Spring and Java workflow

Open a file inside a Maven or Gradle project. Detection recognizes `pom.xml`, Maven/Gradle wrappers and build files. General project roots also recognize normal `.git` directories and `.git` files used by Git worktrees, while deliberately avoiding the home directory as a Git project root.

`<leader>jp` discovers `application-<profile>.properties`, `.yml`, and `.yaml` under conventional `src/main/resources` paths, including nested modules. Build output, generated content, dependencies, VCS metadata, and IDE directories are pruned. Profiles are ordered with `default` first and then alphabetically.

Selection is persisted per normalized project root in Neovim's state directory. If the profile file disappears, selection falls back to `default` and stale state is repaired.

Run and debug environments are loaded in this precedence order:

1. `<project>/.env`
2. `<project>/.env.local`, overriding duplicate keys
3. The selected non-default profile, overriding `SPRING_PROFILES_ACTIVE`

With `default`, a dotenv `SPRING_PROFILES_ACTIVE` is preserved. `.env` and `.env.local` are ignored by this repository; verify your application repository ignores secrets too.

`mvnw`/`gradlew` take precedence. Without a wrapper, `mvn` or `gradle` must be on `PATH`. Run uses `spring-boot:run` or `bootRun`; project tasks also expose test and package/build commands.

## Tasks and REST

Press `<leader>rr` to select a task. Availability depends on the current file/project and executable:

| Source/project | Required executable | Tasks |
| --- | --- | --- |
| C | `gcc` | build; build and run |
| C++ | `g++` | build; build and run |
| Python | `python3` | run current file |
| JavaScript | `node` | run current file |
| TypeScript | `deno` | run current file |
| Ruby | `ruby` | run current file |
| Lua | `lua` | run current file |
| Maven | `mvnw` or `mvn` | Spring run, test, package |
| Gradle | `gradlew` or `gradle` | Spring run, test, build |

C/C++ binaries go under `$XDG_RUNTIME_DIR`, or Neovim's cache directory when it is unset. They never go into the source tree. Use `:OverseerToggle` for task output and history.

In an `.http` file, `<leader>Rs` sends a request, `<leader>Ri` inspects it, and `<leader>Rn`/`<leader>Rp` move between requests. Other actions appear under `<leader>R` in which-key.

## Optional Linux integrations

### Omarchy themes

Omarchy can generate [`lua/plugins/theme.lua`](lua/plugins/theme.lua) and trigger Lazy's reload event when the desktop theme changes. The integration reapplies the colorscheme and transparency without a restart. On general Linux, the checked-in Tokyo Night fallback works normally.

### Remote clipboard

In tmux, SSH, or Herdr sessions, copies are emitted through OSC 52 for terminal/tmux forwarding. If Wayland and `wl-clipboard` are available, copy and paste also use the Wayland clipboard. Normal local sessions retain Neovim's default clipboard provider. Set `vim.g.omarchy_remote_clipboard_osc52 = false` before setup to suppress OSC 52 emission.

## Useful commands

| Command | Purpose |
| --- | --- |
| `:Lazy` | Inspect, update, and sync plugins |
| `:Mason` | Install and update development tools |
| `:LspInfo` | Inspect language-server attachment |
| `:checkhealth workstation` | Check required workstation tools, Java tooling, paths, themes, and clipboard support |
| `:checkhealth` | Diagnose all Neovim plugins and providers |
| `:OverseerToggle` | Show task status and output |
| `:LazyExtras` | Enable or disable LazyVim extras |

## Configuration layout

- [`init.lua`](init.lua): entry point
- [`lua/config/lazy.lua`](lua/config/lazy.lua): plugin bootstrap and imports
- [`lua/config/options.lua`](lua/config/options.lua): options and LazyVim root specification; global autoformat is disabled here
- [`lua/workstation/`](lua/workstation): testable project-root, tool inventory, and health modules
- [`lua/config/keymaps.lua`](lua/config/keymaps.lua) and [`lua/config/autocmds.lua`](lua/config/autocmds.lua): customization entry points
- [`lua/plugins/`](lua/plugins): plugin specifications and integrations
- [`lua/overseer/template/user/`](lua/overseer/template/user): task definitions
- [`lua/spring_project.lua`](lua/spring_project.lua): Spring profiles, environment, run, and debug helpers
- [`tests/`](tests): headless tests and the Java/JDTLS smoke test

Add personal mappings, options, and autocmds to their matching files. Put focused plugin overrides under `lua/plugins/`, or use `:LazyExtras` for an upstream bundle.

## Testing

The unit tests run with `nvim --clean`; they do not load LazyVim, plugins, Mason state, or personal projects. From this repository:

```sh
nvim --clean --headless -l tests/spring_project.lua
nvim --clean --headless -l tests/root_detection.lua
nvim --clean --headless -l tests/task_output.lua
nvim --clean --headless -l tests/health.lua
nvim --headless -u init.lua '+qa'
stylua --check .
git diff --check
```

The Java integration smoke test uses the minimal Maven project in [`tests/fixtures/java`](tests/fixtures/java) by default. It verifies JDTLS attachment, Java DAP registration, Spring extension loading, and buffer-local Java mappings. It requires the configured JDTLS, Java debug/test, and Spring Mason packages:

```sh
nvim --headless -u init.lua -l tests/java_spring_smoke.lua
```

Set `JAVA_SPRING_SMOKE_FILE` to test another Maven or Gradle project:

```sh
JAVA_SPRING_SMOKE_FILE=/absolute/path/to/Example.java \
  nvim --headless -u init.lua -l tests/java_spring_smoke.lua
```

`stylua --check .` is the canonical formatting gate. It checks all Lua except Omarchy-generated [`lua/plugins/theme.lua`](lua/plugins/theme.lua), which is listed in [`.styluaignore`](.styluaignore).

### Continuous integration

The required GitHub Actions job uses Neovim 0.11.2 and pinned StyLua 2.3.1. It runs formatting, all clean unit tests, an isolated bootstrap of the locked plugin set, full headless startup, and `git diff --check`.

The separately retryable Java integration job uses Temurin JDK 21, caches Lazy and Mason data using `lazy-lock.json`, installs the configured Java tooling with a bounded helper, and runs the fixture-backed smoke test. This job remains visible but non-blocking because external registries and tool downloads can fail independently of the configuration. Superseded runs on the same branch are cancelled, and the workflow has read-only repository permissions.

## Troubleshooting

- Missing icons: select a Nerd Font in the terminal.
- Search is unavailable: install `ripgrep` and restart Neovim.
- LSP does not attach: run `:LspInfo`, then inspect `:Mason` and `:checkhealth`.
- Java actions are missing: wait for JDTLS in a Java buffer and confirm a build marker exists above it.
- Spring run is unavailable: make the wrapper executable or install Maven/Gradle on `PATH`.
- A profile is missing: put `application-<name>.properties`, `.yml`, or `.yaml` under `src/main/resources`.
- Remote clipboard fails: confirm OSC 52 terminal/tmux support; install `wl-clipboard` only for Wayland access.
- Startup fails after update: sync in `:Lazy`, restart, and inspect `:checkhealth` and `:messages`.

See the [LazyVim documentation](https://www.lazyvim.org/) and [Neovim documentation](https://neovim.io/doc/).
