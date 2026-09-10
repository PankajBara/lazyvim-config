# C++ DSA Setup — Usage Report

A LazyVim-based C++ environment tuned for data structures & algorithms,
competitive programming, and general C++ sharpening. The base config already
provided clangd + extensions (inlay hints), codelldb/gdb, clang-format,
Overseer, blink.cmp + friendly-snippets, and the cpp Treesitter parser. This
layer glues it together so single-file problem solving is one or two keys.

## 1. Layout

```
~/dsa/
  .clangd          # compile flags + clang-tidy rules (auto-applied in this tree)
  .clang-format    # contest style (2-space, 100 cols, attached braces)
  template.cpp     # boilerplate source of truth
  USAGE.md         # this file
  README.md        # quick reference
  arrays/  strings/  graphs/  dp/   # one folder per topic
```

`~/dsa/` is auto-detected as the project root (root detection walks `.git`),
so everything beneath it inherits `.clangd` and `.clang-format`. Keep DSA work
**inside** `~/dsa/`; files outside use the global LazyVim defaults.

## 2. Daily workflow

### Create / open a problem
```sh
nvim ~/dsa/arrays/two_sum.cpp
```
- New, empty `.cpp` files are auto-seeded from `template.cpp` (only when empty):
  ```cpp
  #include <bits/stdc++.h>
  using namespace std;

  int main() {
      ios::sync_with_stdio(false);
      cin.tie(nullptr);

      return 0;
  }
  ```
- clangd attaches, inlay hints show, and `bits/stdc++.h` resolves with **0 errors**.
- Edit inside `main()`.

### Build and run
| Key | Action | Overseer task |
|-----|--------|--------------|
| `<leader>rb` | Build only | `C++: Build Current File` |
| `<leader>rc` | Build and run | `C++: Build and Run Current File` |
| `<leader>rt` | Build and run with `in.txt` | `C++: Build and Run with in.txt` |

- The first run opens a horizontal output split and focuses it.
- The executable is written to `$XDG_RUNTIME_DIR/nvim-overseer-cpp/` (or the
  Neovim cache dir if `XDG_RUNTIME_DIR` is unset), named `<file>-<sha256-prefix>`,
  so it never clutters your workspace.
- Compile flags: `-std=c++20 -Wall -Wextra -Wpedantic -g`.
- `<leader>rt` looks for `in.txt` in the source file's directory. If present,
  it pipes it as stdin (`exe < in.txt`); if absent, it runs interactively with
  a "no in.txt" notice.

### Other useful keys (existing LazyVim)
| Key | Action |
|-----|--------|
| `<leader>oo` | `:OverseerRun` — pick any task interactively |
| `<leader>oc` | `:OverseerToggle` — task list |
| `<leader>cf` | Format with clang-format (autoformat is **off** globally; manual) |
| `<leader>ch` | Switch source/header (clangd) |
| `<leader>dd` / `<leader>d?` | DAP: launch / debug (codelldb) |
| `<leader>db` | Toggle breakpoint (DAP) |
| `gR` / `gd` | Rename / go-to-def (clangd) |
| `K` | Hover |
| `]d` `[d` | Next / prev diagnostic |
| `<leader>xx` | Trouble (diagnostics list) |
| `<leader>uf` | Toggle autoformat |

### Snippets (insert mode, then accept with `<Tab>`)
| Trigger | Expands to |
|---------|-----------|
| `main` | Full `int main()` with fast I/O |
| `fastio` | Just the `ios::sync_with_stdio...` lines |
| `fori` | `for (int i = 0; i < n; ++i)` with `$1`/`$2` placeholders |
| `vpai` | `vector<pair<int,int>> v;` |

These complement `friendly-snippets` (general C++ snippets via blink.cmp).

## 3. Feeding sample input

Easiest: drop an `in.txt` next to your `.cpp` and press `<leader>rt`.

```
~/dsa/arrays/two_sum.cpp
~/dsa/arrays/in.txt      <- sample input, read automatically
```

Manual alternative (e.g. to try multiple cases):
```sh
g++ -std=c++20 -O2 a.cpp -o /tmp/a && /tmp/a < in.txt
```

## 4. Debugging a wrong answer

1. `<leader>rc` to reproduce.
2. `<leader>db` to set a breakpoint on the suspect line.
3. `<leader>dd` → "Launch file" → point DAP at the Overseer-built executable
   (`$XDG_RUNTIME_DIR/nvim-overseer-cpp/...`), or rebuild with `g++ -g` yourself.
4. Step through with the DAP UI and inspect variables.

(Overseer already compiles with `-g`, so the binary is debuggable.)

## 5. First-launch checklist

```vim
:Lazy            " sync plugins if needed
:Mason           " confirm clangd / codelldb are installed (clangd extra handles it)
:checkhealth workstation
:checkhealth clangd
```
Then open `~/dsa/arrays/p1.cpp` and press `<leader>rc`.

## 6. Customizing

- **Compiler flags:** edit `CompileFlags.Add` in `~/dsa/.clangd` and the
  `compile` line in `lua/overseer/template/user/cpp_build.lua` if they should differ.
- **Boilerplate:** edit `~/dsa/template.cpp` (new files copy from it at creation).
- **Format style:** edit `~/dsa/.clang-format`.
- **Snippets:** add entries in `lua/snippets/cpp.lua` (native `vim.snippets.add`).
- **clang-tidy strictness:** edit `Diagnostics.ClangTidy.Checks` in `.clangd`.

## 7. Known limitations (by design)

- No in-editor LeetCode (browser per your choice).
- No rich DSA snippet library (basic boilerplate only, per your choice).
- No neotest (Overseer covers build/run; a gtest adapter only helps if you
  adopt GoogleTest).
- `bits/stdc++.h` is GCC-only; it works here because clangd follows g++'s
  include paths. Switching compilers would break that include.
- `<leader>rt` reads a fixed `in.txt` in the source directory; it does not
  multiplex multiple test cases.
