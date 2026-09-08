-- Treesitter enrichment: ensure parsers for the languages this config targets,
-- and enable rainbow delimiters for nested brackets/parens.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "bash",
        "dockerfile",
        "jsonc",
        "lua",
        "markdown",
        "markdown_inline",
        "toml",
        "yaml",
      })
      return opts
    end,
  },
  {
    -- Maintained successor to nvim-ts-rainbow; integrates through Treesitter.
    "HiPhish/rainbow-delimiters.nvim",
    event = "LazyFile",
    opts = {
      strategy = {
        [""] = "rainbow-delimiters.strategy.global",
        lua = "rainbow-delimiters.strategy.local",
      },
      query = {
        [""] = "rainbow-delimiters",
        latex = "rainbow-blocks",
      },
      highlight = {
        "RainbowDelimiter1",
        "RainbowDelimiter2",
        "RainbowDelimiter3",
        "RainbowDelimiter4",
        "RainbowDelimiter5",
        "RainbowDelimiter6",
      },
    },
    config = function(_, opts)
      require("rainbow-delimiters.setup").setup(opts)
    end,
  },
}
