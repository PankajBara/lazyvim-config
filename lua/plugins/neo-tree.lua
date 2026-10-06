return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = function(_, opts)
      opts.filesystem = vim.tbl_deep_extend("force", opts.filesystem or {}, {
        -- Let directory searches match names anywhere in the displayed tree.
        find_by_full_path_words = true,
        window = {
          mappings = {
            ["/"] = "fuzzy_finder_directory",
            ["D"] = "fuzzy_finder_directory",
            ["f"] = "filter_on_submit",
          },
        },
      })
      return opts
    end,
  },
}
