-- Solve LeetCode problems directly inside Neovim.
-- Uses snacks.nvim as the picker (already installed) and runs in non-standalone
-- mode so `:Leet` works even when other buffers are open. The arg launcher
-- (`nvim leetcode.nvim`) stays available too.
return {
  {
    "kawre/leetcode.nvim",
    cmd = "Leet",
    build = ":TSUpdate html",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    lazy = "leetcode.nvim" ~= vim.fn.argv(0, -1),
    opts = {
      lang = "cpp",
      picker = { provider = "snacks" },
      plugins = {
        non_standalone = true,
      },
    },
    keys = {
      {
        "<leader>Le",
        "<cmd>Leet<cr>",
        desc = "LeetCode",
      },
    },
  },
}
