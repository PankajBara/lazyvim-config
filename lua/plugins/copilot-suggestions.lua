vim.g.ai_cmp = true

return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "copilot-language-server" })
      return opts
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        copilot = {},
      },
    },
  },
  {
    "saghen/blink.cmp",
    dependencies = { "fang2hou/blink-copilot" },
    opts = function(_, opts)
      opts.completion = opts.completion or {}
      opts.completion.ghost_text = vim.tbl_deep_extend(
        "force",
        opts.completion.ghost_text or {},
        { enabled = true }
      )

      opts.sources = opts.sources or {}
      opts.sources.default = opts.sources.default or {}
      if not vim.tbl_contains(opts.sources.default, "copilot") then
        table.insert(opts.sources.default, "copilot")
      end

      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers.copilot = vim.tbl_deep_extend(
        "force",
        opts.sources.providers.copilot or {},
        {
          name = "Copilot",
          module = "blink-copilot",
          score_offset = 100,
          async = true,
        }
      )
    end,
  },
}
