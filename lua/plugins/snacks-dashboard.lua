-- Theme-aware Snacks dashboard: a centered header with the active colorscheme,
-- quick keys for the most common actions, and recent files/projects. Styling
-- only uses existing highlight groups, so it stays correct across Omarchy
-- theme hot-reloads.
return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      local function hl(group)
        return vim.api.nvim_get_hl(0, { name = group, link = false })
      end

      -- Resolve the active colorscheme name for the header (falls back to the
      -- colorscheme Snacks/Omarchy set, else a neutral label).
      local colorscheme = vim.g.colors_name or "default"

      opts.dashboard = vim.tbl_deep_extend("force", opts.dashboard or {}, {
        preset = {
          header = "Neovim",
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { section = "projects", title = "Projects", icon = "󰉗 ", filter = function(dir) return dir:match("/%.git$") == nil end },
          { section = "recent_files", title = "Recent Files", icon = "󰈔 " },
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
