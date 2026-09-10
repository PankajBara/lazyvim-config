-- Small, theme-aware visual refinements.  These intentionally use existing
-- highlight groups so Omarchy can continue to hot-reload the active theme.
return {
  {
    -- Minimal chrome: no top buffer/tab bar.
    "akinsho/bufferline.nvim",
    enabled = false,
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- Flat, near-empty statusline: no separators, no icons, filename only.
      opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        globalstatus = true,
        always_divide_middle = false,
        icons_enabled = false,
      })
      opts.sections = opts.sections or {}
      opts.sections.lualine_a = {
        { "mode", padding = { left = 1, right = 0 } },
      }
      opts.sections.lualine_b = {
        { "filename", path = 1, symbols = { modified = "●", readonly = "󰌾", unnamed = "" } },
      }
      opts.sections.lualine_c = {}
      opts.sections.lualine_x = {}
      opts.sections.lualine_y = {}
      opts.sections.lualine_z = {}
      return opts
    end,
  },
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.notifier = vim.tbl_deep_extend("force", opts.notifier or {}, {
        style = "compact",
        timeout = 3000,
      })
      opts.input = vim.tbl_deep_extend("force", opts.input or {}, { icon = "󰘵 " })
      return opts
    end,
    config = function(_, opts)
      -- This config function replaces LazyVim's default Snacks callback, so
      -- keep the actual plugin setup here before registering UI refinements.
      local notify = vim.notify
      require("snacks").setup(opts)
      if LazyVim.has("noice.nvim") then
        vim.notify = notify
      end

      local group = vim.api.nvim_create_augroup("WorkstationUiPolish", { clear = true })

      local function set_active_cursorline(win)
        if not vim.api.nvim_win_is_valid(win) then
          return
        end
        local bufnr = vim.api.nvim_win_get_buf(win)
        local ft = vim.bo[bufnr].filetype
        local quiet = {
          help = true,
          lazy = true,
          mason = true,
          neo_tree = true,
          snacks_dashboard = true,
          qf = true,
        }
        vim.wo[win].cursorline = not quiet[ft]
      end

      vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
        group = group,
        callback = function(args)
          set_active_cursorline(args.win or vim.api.nvim_get_current_win())
        end,
      })
      vim.api.nvim_create_autocmd("WinLeave", {
        group = group,
        callback = function(args)
          local win = args.win or vim.api.nvim_get_current_win()
          if vim.api.nvim_win_is_valid(win) then
            vim.wo[win].cursorline = false
          end
        end,
      })

      local function polish_highlights()
        local function get(group_name, key)
          local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group_name, link = false })
          if not ok then
            return nil
          end
          return hl[key]
        end
        local function hex(value)
          return value and string.format("#%06x", value) or nil
        end
        -- Derive accent/muted from syntax groups so this stays correct
        -- across Omarchy hot-reloads (the pastel palette flows through here).
        local accent = hex(get("Identifier", "fg")) or hex(get("Special", "fg"))
        local muted = hex(get("Comment", "fg"))
        if accent then
          vim.api.nvim_set_hl(0, "CursorLineNr", { fg = accent, bold = true })
          vim.api.nvim_set_hl(0, "FloatBorder", { fg = accent })
          vim.api.nvim_set_hl(0, "MatchParen", { fg = accent, bold = true, underline = true })
          vim.api.nvim_set_hl(0, "WinSeparator", { fg = accent, nocombine = true })
        end
        if muted then
          vim.api.nvim_set_hl(0, "LineNr", { fg = muted })
          vim.api.nvim_set_hl(0, "Folded", { fg = muted, italic = true })
          vim.api.nvim_set_hl(0, "StatusLineNC", { fg = muted })
        end
        -- Keep a near-invisible separator for the trimmed statusline.
        vim.api.nvim_set_hl(0, "StatusLine", { fg = "NONE", bg = "NONE" })
      end

      vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = polish_highlights })
      polish_highlights()
    end,
  },
}
