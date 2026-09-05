-- Java/Spring workstation integration. The Java extra owns the JDTLS lifecycle;
-- this file augments its settings and adds Spring-aware tooling around it.
return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      local tools = require("workstation.tools")
      vim.list_extend(opts.ensure_installed, tools.mason_java)
      vim.list_extend(opts.ensure_installed, tools.mason_ai)
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
      local group = vim.api.nvim_create_augroup("JavaSpringJdtls", { clear = true })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = group,
        pattern = "*.java",
        callback = function(args)
          local bufnr = args.buf
          local is_stopped = function(client)
            if type(client.is_stopped) == "function" then
              local ok, stopped = pcall(client.is_stopped, client)
              return ok and stopped or false
            end
            return client.is_stopped == true
          end
          if not vim.api.nvim_buf_is_valid(bufnr) then
            return
          end

          local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "jdtls" })
          if #clients == 0 then
            return
          end
          clients = vim.tbl_filter(function(client)
            return not is_stopped(client)
          end, clients)
          if #clients == 0 then
            return
          end

          local line_count = vim.api.nvim_buf_line_count(bufnr)
          local last_line = math.max(line_count - 1, 0)
          local last_text = vim.api.nvim_buf_get_lines(bufnr, last_line, last_line + 1, false)[1] or ""
          local params = {
            textDocument = { uri = vim.uri_from_bufnr(bufnr) },
            range = {
              start = { line = 0, character = 0 },
              ["end"] = { line = last_line, character = #last_text },
            },
            context = {
              only = { "quickfix" },
              diagnostics = vim.diagnostic.get(bufnr),
            },
          }

          vim.lsp.buf_request_all(bufnr, "textDocument/codeAction", params, function(responses)
            if not vim.api.nvim_buf_is_valid(bufnr) then
              return
            end
            for client_id, response in pairs(responses or {}) do
              local result = response and response.result
              if result then
                local client = vim.lsp.get_client_by_id(client_id)
                if client and not is_stopped(client) then
                  for _, action in ipairs(result) do
                    local title = type(action.title) == "string" and action.title or ""
                    if title:lower():match("add[%w%s]*import") and action.edit then
                      pcall(
                        vim.lsp.util.apply_workspace_edit,
                        action.edit,
                        client.offset_encoding or "utf-16"
                      )
                    end
                  end
                end
              end
            end
            if #clients > 0 then
              pcall(require("jdtls").organize_imports)
            end
          end)
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
          configuration = { updateBuildConfiguration = "automatic", runtimes = {} },
          maven = { downloadSources = true, updateSnapshots = true },
          gradle = { enabled = true, downloadSources = true },
          lombok = { enabled = true },
          import = { gradle = { enabled = true }, maven = { enabled = true } },
        },
      })
      opts.dap = vim.tbl_deep_extend("force", opts.dap or {}, { hotcodereplace = "auto" })
      -- Standalone .java files (no Maven/Gradle/.git markers) resolve to nil with
      -- the default root_dir, which prevents JDTLS from attaching. Fall back to the
      -- file's own directory so LSP, DAP, and diagnostics work for single files.
      opts.root_dir = function(path)
        return vim.fs.root(path, vim.lsp.config.jdtls.root_markers) or vim.fs.dirname(vim.api.nvim_buf_get_name(0))
      end
      local previous_on_attach = opts.on_attach
      opts.on_attach = function(args)
        if previous_on_attach then
          previous_on_attach(args)
        end
        local spring = require("spring_project")
        local map = function(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
        end
        local test_overrides = function()
          local root = spring.root(args.buf)
          return root and { env = spring.env(root) } or nil
        end
        map("<leader>jp", function()
          spring.select_profile(args.buf)
        end, "Select Spring Profile")
        map("<leader>jr", function()
          spring.run(args.buf)
        end, "Run Spring Boot")
        map("<leader>jd", function()
          spring.debug_main(args.buf)
        end, "Debug Java Main Class")
        map("<leader>ja", function()
          spring.attach(args.buf)
        end, "Attach Remote JVM")
        map("<leader>tt", function()
          require("jdtls.dap").test_class({ config_overrides = test_overrides() })
        end, "Run All Test")
        map("<leader>tr", function()
          require("jdtls.dap").test_nearest_method({ config_overrides = test_overrides() })
        end, "Run Nearest Test")
        map("<leader>tT", function()
          require("jdtls.dap").pick_test({ config_overrides = test_overrides() })
        end, "Run Test")
        map("<leader>td", function()
          local overrides = test_overrides() or {}
          overrides.noDebug = false
          require("jdtls.dap").test_nearest_method({ config_overrides = overrides })
        end, "Debug Nearest Test")
        map("<leader>tl", function()
          require("dap").run_last()
        end, "Rerun Last Java Test/Debug")
      end
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
        "user.java_single_file",
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
      {
        "<leader>as",
        function()
          require("sidekick.cli").select({ filter = { installed = true } })
        end,
        desc = "Select Installed Agent",
      },
    },
  },
}
