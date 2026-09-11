# LeetCode — leetcode.nvim Usage

Solve LeetCode problems directly inside Neovim with `leetcode.nvim` (kawre).
This config wires it into LazyVim with the **snacks.nvim** picker, **C++** as the
default language (switch per-question to Java or others), and **non-standalone**
mode so `:Leet` works even when other buffers are open.

- Plugin spec: `lua/plugins/leetcode.lua`
- Picker: snacks (already installed)
- Languages: default `cpp`; use `:Leet lang` to switch to `java` (or others)

> Note: this replaces the earlier "browser-only" LeetCode workflow described in
> `DSA_USAGE.md`. You can use both — keep hand-rolled `.cpp` practice in `~/dsa/`
> for clangd/debugging, and `leetcode.nvim` for the real site with run/submit.

## 1. Launch

Two ways to open the LeetCode dashboard:

| Method | What it does |
|--------|--------------|
| `:Leet` or `<leader>Le` | Open inside your current Neovim session (non-standalone) |
| `nvim leetcode.nvim` (from a shell) | Dedicated standalone session |

The first launch shows a login prompt — see §5.

## 2. Commands

All commands are subcommands of `:Leet`. Most can be run from the dashboard or
directly from the command line.

| Command | Action |
|---------|--------|
| `:Leet` / `:Leet menu` | Open the dashboard |
| `:Leet exit` | Close leetcode.nvim (works because non_standalone is on) |
| `:Leet daily` | Open today's daily question |
| `:Leet random` | Open a random question |
| `:Leet list` | Picker of all problems (filterable) |
| `:Leet tabs` | Picker of currently open question tabs |
| `:Leet lang` | Picker to change the current question's language |
| `:Leet run` / `:Leet test` | Run / test the open question against cases |
| `:Leet submit` | Submit the open question |
| `:Leet console` | Open the console popup for the open question |
| `:Leet info` | Popup with info about the open question |
| `:Leet yank` | Yank the code section |
| `:Leet open` | Open the current question in a browser |
| `:Leet reset` | Reset editor code to the default snippet |
| `:Leet restore` | Restore the default question layout |
| `:Leet last_submit` | Replace editor code with your last submission |
| `:Leet inject` | Re-inject editor code, keeping the code section intact |
| `:Leet fold` | Fold the imports section of the current question |
| `:Leet desc toggle` / `:Leet desc stats` | Toggle description / description stats |
| `:Leet cookie update` | Prompt to enter a new LeetCode cookie (login) |
| `:Leet cookie delete` | Log out (delete stored cookie) |
| `:Leet cache update` | Re-fetch all problems and refresh the local cache |

### Command arguments

Some commands take space-separated `key=value` args (comma to stack values):

```vim
:Leet list status=todo difficulty=medium
:Leet random difficulty=easy tags=array,string
```

## 3. In-question keymaps

These are active while a question buffer is open (defaults shown):

| Key (default) | Action |
|---------------|--------|
| `q` | Toggle / close the question UI |
| `<CR>` | Confirm (run the focused test case, etc.) |
| `r` | Reset test cases |
| `U` | Use (toggle) a test case |
| `H` | Focus the test cases panel |
| `L` | Focus the result panel |
| `1`, `2`, … | Switch to Case (1), Case (2), … |

## 4. Typical workflow

1. `:Leet daily` (or `:Leet list` to browse by difficulty/tag/status).
2. Solve in the editor. Switch language with `:Leet lang` if you want Java.
3. `:Leet run` to test against the cases; results appear in the console panel.
4. `:Leet submit` when ready; the result (Accepted / Wrong Answer) shows in-place.
5. `:Leet tabs` to jump between open questions; `:Leet exit` to leave.

## 5. Signing in (one-time)

LeetCode authenticates via a **session cookie**, not a username/password.

1. Open leetcode.com in your browser and log in.
2. Open DevTools (F12) → **Network** tab → click any request to leetcode.com.
3. In **Request Headers**, copy the full value of the `Cookie` header
   (use **Cookie**, not `set-cookie` from the response).
4. In Neovim run `:Leet cookie update` and paste it.

If you keep getting `cookie expired`, LeetCode is likely rate-limiting API
access (common during contests) — wait, and disable any VPN.

## 6. Customizing

Edit `lua/plugins/leetcode.lua` → `opts`. Common knobs:

```lua
  opts = {
  lang = "cpp",                       -- default language
  picker = { provider = "snacks-picker" },  -- snacks-picker / fzf-lua / telescope / mini-picker
  plugins = { non_standalone = true },
  injector = {                       -- inject code that isn't submitted
    cpp = {
      imports = function()
        return { "#include <bits/stdc++.h>", "using namespace std;" }
      end,
      after = "int main() {}",
    },
    java = {
      imports = function()
        return { "import java.util.*;", "import java.util.stream.*;" }
      end,
    },
  },
  image_support = true,              -- render problem diagrams (needs image.nvim)
}
```

Description formatting needs the `html` treesitter parser, which this config
adds to `ensure_installed` in `lua/plugins/treesitter.lua`.

## 7. Troubleshooting

| Symptom | Fix |
|---------|-----|
| `cookie expired` | Re-run `:Leet cookie update` with a fresh Cookie |
| No LSP completions (e.g. Rust/Java) | Extra per-language setup may be needed |
| Description looks unformatted | Ensure `html` parser is installed (`:TSUpdate html`) |
| Can't open `:Leet` with buffers open | `non_standalone` is enabled; if still blocked, `:Leet exit` first |
