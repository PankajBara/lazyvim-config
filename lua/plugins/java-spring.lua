-- Java/Spring workstation integration. The Java extra owns the JDTLS lifecycle;
-- this file augments its settings and adds Spring-aware tooling around it.
return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "jdtls",
        "java-debug-adapter",
        "java-test",
        "vscode-spring-boot-tools",
        "copilot-language-server",
      })
      return opts
    end,
  },
  {
    "JavaHello/spring-boot.nvim",
    ft = { "java", "yaml", "jproperties" },
    opts = {},
  },
  {
    "mfussenegger/nvim-jdtls",
    dependencies = { "JavaHello/spring-boot.nvim" },
    init = function()
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.java",
        callback = function()
          if vim.lsp.get_clients({ bufnr = 0, name = "jdtls" })[1] then
            pcall(require("jdtls").organize_imports)
          end
        end,
      })
    end,
    opts = function(_, opts)
      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          signatureHelp = { enabled = true },
          references = { includeDecompiledSources = true },
          implementationsCodeLens = { enabled = true },
          referencesCodeLens = { enabled = true },
          completion = {
            importOrder = { "java", "javax", "org", "com" },
            guessMethodArguments = true,
            favoriteStaticMembers = {
              "org.junit.jupiter.api.Assertions.*",
              "org.mockito.Mockito.*",
              "org.assertj.core.api.Assertions.*",
              "org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*",
              "org.springframework.test.web.servlet.result.MockMvcResultMatchers.*",
            },
          },
          sources = {
            organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 },
            rename = { enabled = true },
          },
          format = { enabled = true },
          saveActions = { organizeImports = true },
          configuration = { updateBuildConfiguration = "automatic", runtimes = {} },
          maven = { downloadSources = true, updateSnapshots = true },
          gradle = { enabled = true, downloadSources = true },
          lombok = { enabled = true },
          import = { gradle = { enabled = true }, maven = { enabled = true } },
        },
      })
      opts.dap = vim.tbl_deep_extend("force", opts.dap or {}, { hotcodereplace = "auto" })
      opts.jdtls = function(config)
        config.init_options = config.init_options or {}
        config.init_options.bundles = config.init_options.bundles or {}
        vim.list_extend(config.init_options.bundles, require("spring_boot").java_extensions())
        return config
      end
      return opts
    end,
  },
  {
    "stevearc/overseer.nvim",
    keys = {
      { "<leader>rr", "<cmd>OverseerRun<cr>", desc = "Run Project Task" },
    },
    opts = function(_, opts)
      opts.templates = {
        "builtin",
        "user.java_build",
        "user.cpp_build",
        "user.current_file",
      }
      return opts
    end,
  },
  {
    "folke/sidekick.nvim",
    opts = function(_, opts)
      opts.cli = opts.cli or {}
      opts.cli.tools = opts.cli.tools or {}
      opts.cli.tools.codex = { cmd = "codex", name = "Codex" }
      opts.cli.tools.claude = { cmd = "claude", name = "Claude" }
      opts.cli.tools.copilot = { cmd = "copilot", name = "Copilot" }
      return opts
    end,
    keys = {
      { "<leader>as", function() require("sidekick.cli").select({ filter = { installed = true } }) end, desc = "Select Installed Agent" },
    },
  },
}
