-- Theme-aware Snacks dashboard: a centered header with the active colorscheme,
-- quick keys for the most common actions, and recent files/projects. Styling
-- only uses existing highlight groups, so it stays correct across Omarchy
-- theme hot-reloads.
return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.dashboard = vim.tbl_deep_extend("force", opts.dashboard or {}, {
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
          { section = "header", padding = { bottom = 2, top = 1 } },
          { section = "keys", gap = 1, padding = { bottom = 2 } },
          {
            section = "projects",
            title = " Projects",
            icon = "󰉗 ",
            indent = 2,
            padding = { bottom = 1 },
            filter = function(dir)
              return dir:match("/%.git$") == nil
            end,
          },
          { section = "recent_files", title = " Recent Files", icon = "󰈔 ", indent = 2, padding = { bottom = 2 } },
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
  },
}
