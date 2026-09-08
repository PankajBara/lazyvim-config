-- Snacks UI polish: indent guides and the animated scope indicator.
-- These modules already ship enabled by LazyVim; this file only tunes them.
-- No custom highlight groups are introduced, so Omarchy's theme hot-reload
-- (which clears and reapplies highlights) is unaffected.
return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.indent = vim.tbl_deep_extend("force", opts.indent or {}, {
        enabled = true,
        animate = { enabled = true },
        char = "│",
        blank = " ",
      })
      opts.scope = vim.tbl_deep_extend("force", opts.scope or {}, {
        enabled = true,
        animate = true,
        indent = { enabled = true },
        exclude = {
          languages = {},
          filetypes = { "lazy", "mason", "neo-tree", "snacks_dashboard", "help", "txt", "markdown" },
        },
      })
      return opts
    end,
  },
}
