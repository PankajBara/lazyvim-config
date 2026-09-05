return {
  mason_java = {
    "jdtls",
    "java-debug-adapter",
    "java-test",
    "vscode-spring-boot-tools",
  },
  -- Copilot's native Neovim completion/language server is intentionally not
  -- installed. Sidekick and CodeCompanion use the authenticated `copilot`
  -- CLI directly instead.
  mason_ai = {},
}
