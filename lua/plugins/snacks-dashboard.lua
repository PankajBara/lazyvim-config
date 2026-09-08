-- Theme-aware Snacks dashboard: a centered header with the active colorscheme,
-- quick keys for the most common actions, and recent files/projects. Styling
-- only uses existing highlight groups, so it stays correct across Omarchy
-- theme hot-reloads.
return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.dashboard = vim.tbl_deep_extend("force", opts.dashboard or {}, {
        enabled = true,
        width = 64,
        pane_gap = 5,
        preset = {
          header = [[
╭──────────────────────────────────────────────╮
│                  N E O V I M                 │
│            a calm place to build             │
╰──────────────────────────────────────────────╯]],
        },
        sections = {
          { section = "header", padding = { 1, 2 } },
          { section = "keys", gap = 1, padding = { 0, 2 } },
          {
            section = "projects",
            title = " Projects",
            icon = "󰉗 ",
            indent = 2,
            padding = { 0, 1 },
            filter = function(dir)
              return dir:match("/%.git$") == nil
            end,
          },
          { section = "recent_files", title = " Recent Files", icon = "󰈔 ", indent = 2, padding = { 0, 2 } },
          { section = "startup", icon = "󰄉 " },
        },
        keys = {
          { icon = "󰉖 ", key = "<leader>e", desc = "Explorer", action = ":Neotree focus<cr>" },
          { icon = "󰈞 ", key = "<leader>ff", desc = "Find File", action = ":Snacks picker files<cr>" },
          { icon = "󰈞 ", key = "<leader>fg", desc = "Live Grep", action = ":Snacks picker grep<cr>" },
          { icon = "󰊂 ", key = "<leader>gg", desc = "Lazygit", action = ":LazyGit<cr>" },
          { icon = "󰓌 ", key = "<leader>rr", desc = "Run Task", action = ":OverseerRun<cr>" },
          { icon = "󰒲 ", key = "<leader>l", desc = "Lazy", action = ":Lazy<cr>" },
          { icon = "󰓋 ", key = "q", desc = "Quit", action = ":qa<cr>" },
        },
      })
      return opts
    end,
    init = function()
      -- Snacks normally opens the dashboard from its UIEnter handler. Keep a
      -- small, guarded fallback for startup paths where that handler is
      -- installed after UIEnter has already fired.
      local group = vim.api.nvim_create_augroup("WorkstationSnacksDashboard", { clear = true })
      local attempted = false

      local function is_empty_startup_window()
        if vim.fn.argc(-1) > 0 or #vim.api.nvim_list_uis() == 0 then
          return false
        end

        local win = vim.api.nvim_get_current_win()
        if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_config(win).relative ~= "" then
          return false
        end

        local buf = vim.api.nvim_win_get_buf(win)
        if vim.api.nvim_buf_get_name(buf) ~= "" or vim.bo[buf].modified then
          return false
        end

        return vim.api.nvim_buf_line_count(buf) == 1
          and (vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or "") == ""
      end

      local function open_dashboard()
        if attempted or not is_empty_startup_window() then
          return
        end

        local ok, snacks = pcall(require, "snacks")
        if not ok or not snacks.did_setup or not snacks.config.dashboard.enabled then
          return
        end

        -- The regular Snacks UIEnter setup may have won the race already.
        if snacks.dashboard.status.opened then
          attempted = true
          return
        end

        attempted = true
        vim.schedule(function()
          if not is_empty_startup_window() or snacks.dashboard.status.opened then
            return
          end
          pcall(snacks.dashboard)
        end)
      end

      vim.api.nvim_create_autocmd({ "VimEnter", "UIEnter" }, {
        group = group,
        callback = open_dashboard,
      })
    end,
  },
}
