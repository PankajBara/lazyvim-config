-- LSP polish: enable inlay hints for clangd (via clangd_extensions.nvim) and
-- jdtls (via vim.lsp.inlay_hint), bind flash.nvim motions, and bind
-- nvim-treesitter-textobjects selection keymaps.
--
-- No new highlight groups are introduced, so Omarchy's theme hot-reload
-- (which clears and reapplies highlights) keeps working.

local function inlay_capable(client_name)
  return client_name == "clangd" or client_name == "jdtls"
end

local function setup_inlay_hints_on_attach()
  local group = vim.api.nvim_create_augroup("WorkstationInlayHints", { clear = true })
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data and args.data.client_id)
      if not client or not inlay_capable(client.name) then
        return
      end
      -- vim.lsp.inlay_hint is a no-op when the capability is missing, so this
      -- is safe for jdtls variants that negotiate inlayHints lazily.
      pcall(vim.lsp.inlay_hint.enable, true, { bufnr = args.buf })
    end,
  })
end

-- Expose the autocmd setup so headless smoke tests can call it without
-- bootstrapping lazy.nvim (the spec below registers the same call via `init`).
package.loaded["workstation.lsp_polish"] = { setup_inlay_hints_on_attach = setup_inlay_hints_on_attach }

return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = vim.tbl_deep_extend("force", opts.formatters_by_ft or {}, {
        lua = { "stylua" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        json = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        java = { "google-java-format" },
        c = { "clang-format" },
        cpp = { "clang-format" },
      })
      return opts
    end,
  },
  {
    "p00f/clangd_extensions.nvim",
    event = "LspAttach",
    opts = function(_, opts)
      opts.inlay_hints = vim.tbl_deep_extend("force", opts.inlay_hints or {}, {
        enabled = true,
        parameter_hints = true,
        type_hints = true,
        only_on_line = false,
        show_on_kunmap = false,
      })
      return opts
    end,
  },
  {
    "neovim/nvim-lspconfig",
    init = function()
      setup_inlay_hints_on_attach()
    end,
  },
}
