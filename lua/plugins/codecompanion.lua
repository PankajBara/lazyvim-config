-- In-editor AI chat and inline edits backed by the GitHub Copilot CLI (ACP).
-- Requires an authenticated `copilot` CLI on PATH (the same GitHub account used
-- by the copilot-native completion extra); it reuses that login with no extra
-- auth step. Run `copilot auth` once if the CLI has not been signed in.
return {
	{
		"olimorris/codecompanion.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
		opts = {
			interactions = {
				chat = {
					adapter = "copilot_acp",
					opts = {
						context_management = {
							compaction = { enabled = true },
						},
					},
				},
				inline = {
					adapter = "copilot_acp",
				},
			},
		},
		keys = {
			{
				"<leader>ac",
				"<cmd>CodeCompanionChat<cr>",
				desc = "CodeCompanion Chat",
				mode = { "n", "v" },
			},
			{
				"<leader>aa",
				"<cmd>CodeCompanion<cr>",
				desc = "CodeCompanion Inline",
				mode = { "n", "v" },
			},
			{
				"<leader>ai",
				"<cmd>CodeCompanionActions<cr>",
				desc = "CodeCompanion Actions",
				mode = { "n", "v" },
			},
		},
	},
}
