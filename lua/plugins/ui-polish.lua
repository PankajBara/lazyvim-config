-- Small, theme-aware visual refinements.  These intentionally use existing
-- highlight groups so Omarchy can continue to hot-reload the active theme.
return {
  {
    -- Modern buffer/tab bar at the top, themed to match Solarized Osaka.
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        mode = "buffers",
        numbers = "none",
        close_command = "bdelete! %d",
        right_mouse_command = "bdelete! %d",
        hover = "enabled",
        separator_style = "rounded",
        show_buffer_close_icons = false,
        show_close_icon = false,
        show_tab_indicators = true,
        show_duplicate_prefix = true,
        persist_buffer_sort = true,
        enforce_regular_tabs = false,
        always_show_bufferline = true,
        max_name_length = 24,
        diagnostics = "nvim-lsp",
        diagnostics_update_in_insert = false,
        diagnostics_indicator = function(_, _, diag)
          local icons = { error = "󰅚 ", warn = "󰀪 ", info = "󰋽 ", hint = "󰌶 " }
          local result = {}
          for name, count in pairs(diag) do
            if icons[name] and count > 0 then
              table.insert(result, icons[name] .. count)
            end
          end
          return table.concat(result, " ")
        end,
      },
      -- Solarized Osaka palette; the editor stays transparent while the
      -- bufferline keeps solid, readable colors.
      highlights = {
        fill = { fg = { from = "tabline_fg" }, bg = { from = "tabline_bg" } },
        background = { fg = { from = "comment" }, bg = { from = "tabline_bg" } },
        buffer_selected = {
          fg = { from = "normal_fg" },
          bg = { from = "tabline_sel_bg" },
          bold = true,
          italic = true,
        },
        separator_selected = { fg = { from = "tabline_sel_bg" }, bg = { from = "tabline_bg" } },
        separator_visible = { fg = { from = "tabline_bg" }, bg = { from = "tabline_bg" } },
        close_button = { fg = { from = "comment" }, bg = { from = "tabline_bg" } },
        close_button_visible = { fg = { from = "comment" }, bg = { from = "tabline_bg" } },
        close_button_selected = { fg = { from = "normal_fg" }, bg = { from = "tabline_sel_bg" } },
        indicator_selected = { fg = { from = "tabline_sel_bg" }, bg = { from = "tabline_sel_bg" } },
        pick_selected = { fg = { from = "tabline_sel_bg" }, bg = { from = "tabline_fg" } },
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- Polished Solarized Osaka powerline statusline.
      opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
        theme = "solarized-osaka",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        globalstatus = true,
        always_divide_middle = true,
        icons_enabled = true,
      })

      local function lsp_names()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then
          return ""
        end
        local names = {}
        for _, c in ipairs(clients) do
          names[#names + 1] = c.name
        end
        return "󰄴 " .. table.concat(names, ", ")
      end

      opts.sections = opts.sections or {}
      opts.sections.lualine_a = {
        { "mode", padding = { left = 1, right = 0 } },
      }
      opts.sections.lualine_b = {
        { "branch", icon = "" },
        { "diff", symbols = { added = " ", modified = " ", removed = " " } },
      }
      opts.sections.lualine_c = {
        {
          "filename",
          path = 1,
          symbols = { modified = "●", readonly = "󰌾", unnamed = "" },
        },
      }
      opts.sections.lualine_x = {
        { "diagnostics", symbols = { error = "󰅚 ", warn = "󰀪 ", info = "󰋽 ", hint = "󰌶 " } },
        { lsp_names, cond = function() return #vim.lsp.get_clients({ bufnr = 0 }) > 0 end },
        { "encoding", cond = function() return vim.bo.fileencoding ~= "utf-8" end },
        { "fileformat", symbols = { unix = "", dos = "", mac = "" } },
        { "filetype", icon_only = true },
      }
      opts.sections.lualine_y = {
        { "location" },
      }
      opts.sections.lualine_z = {
        { "progress", padding = { left = 0, right = 1 } },
      }

      -- Soft, rounded inactive statusline instead of bare text.
      opts.inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { { "filename", path = 1 } },
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      }
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
