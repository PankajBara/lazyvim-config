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
      {
        "3rd/image.nvim",
        config = function(_, opts)
          require("image").setup(opts)
        end,
        opts = {
          backend = "sixel",
          integrations = {
            markdown = { enabled = false },
            neorg = { enabled = false },
            telescope = { enabled = false },
          },
        },
      },
    },
    lazy = "leetcode.nvim" ~= vim.fn.argv(0, -1),
    opts = {
      lang = "cpp",
      picker = { provider = "snacks-picker" },
      plugins = {
        non_standalone = true,
      },
      injector = {
        cpp = {
          imports = function()
            return { "#include <bits/stdc++.h>", "using namespace std;" }
          end,
          after = "int main() {}",
        },
        java = {
          imports = function()
            return { "import java.util.*;", "import java.util.stream.*;" }
          end,
        },
      },
      image_support = true,
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
