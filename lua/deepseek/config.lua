local M = {}

M.default_config = {
	config = {
		order = 0,
		disable = true,
	},
	log = {
		order = 1,
		log_level = "2", -- 0 - DEBUG, 1 - INFO, 2 - WARN, 3 - ERROR
		enable_trace = false, -- true on TRACE
		plugin_name = "deepseek.nvim",
	},
	api = {
		order = 2,
		key = nil,
		url = "https://api.deepseek.com",
		default_model = "deepseek-chat",
		stream_timeout = 0, -- response timeout after which the connection is terminated, 0 - do not terminate the connection by timeout
	},
	keymaps = {
		order = 99,
		generate_code = "<leader>ag",
		optimize_code = "<leader>ao",
		analyze_code = "<leader>az",
		translate = "<leader>at",
		improve = "<leader>ai",
		chat = {
			default = "<leader>acc",
			popup = "<leader>acp",
			left = "<leader>acl",
			right = "<leader>acr",
			top = "<leader>act",
			bottom = "<leader>acb",
		},
	},
	ui = {
		order = 10,
		loader = {
			loader_prefix = "AI in progress ",
			loader_postfix = "",
			load_success = "AI done!",
		},
		window = {
			default_position = "float", -- float, left, right, top, bottom
			width = 0.7, -- float window width ratio
			height = 0.6, -- float window height ratio
			min_width = 15, -- minimum chat window width
			min_height = 15, -- minimum chat window height
			border = "rounded", -- window border style
		},
	},
	core = {
		order = 60,
		model = "deepseek-chat",
		base_command = {
			order = 1,
			enable_memory = true,
		},
		chat = {
			stream_mode = true,
			disable = false,
			model = "deepseek-chat", -- deepseek-chat or deepseek-reasoner
			system_prompt = "You are an AI assistant helping with the %s programming language",
			max_history = 10,
			enable_memory = true,
			hi_message = {
				"┌─────────────────────────────────────────────┐",
				"│           Welcome to Deepseek chat!         │",
				"│  Insert-mode: <C-i> to send, <C-q> to exit  │",
				"│  Normal-mode: <Enter> to send, <q> to exit  │",
				"│               Enjoy using it                │",
				"└─────────────────────────────────────────────┘",
			},
			reasoning_start_message = "[------------------- **START** Reasoning -------------------]",
			reasoning_end_message = "[---------------  **END** Reasoning ---------------]",
		},
		translate = {
			model = "deepseek-chat",
			system_prompt = "You are a translator. You receive text and translate it into the %s language. Your response should contain only the translation, without explanations. If the text is already in the target language, return the translation in the %s language. Do not add quotation marks if they were not in the original message, preserve indentation and special characters at the beginning of lines if they were present in the original message.",
			language = "English",
			second_language = "Russian",
			max_tokens = 4096,
			temperature = 1.5,
			enable_memory = false,
		},
		improve = {
			model = "deepseek-chat",
			system_prompt = "Reply only with the corrected text, without introductory words, explanations, or closing phrases. Don't write: 'Here is the corrected text', 'As you requested', 'If you need help', etc. Simply return the improved version of the text right away.",
			max_tokens = 4096,
			temperature = 0.7,
			enable_memory = false,
		},
		generate_code = {
			model = "deepseek-chat",
			system_prompt = "You are a senior %s developer. You don't have time for greetings and politeness, but you're excellent at coding. Write ONLY code. Be brief and concise. Explain only if asked.",
			max_tokens = 4096,
			temperature = 0.0,
		},
		optimize_code = {
			model = "deepseek-chat",
			system_prompt = "You are a senior %s developer. You don't have time for greetings and politeness, but you're excellent at coding. Be brief and concise. Improve the code, add comments and docstrings if needed",
			max_tokens = 4096,
			temperature = 0.2,
		},
		analyze_code = {
			model = "deepseek-chat",
			system_prompt = "You are a senior %s developer. You want to teach a beginner to code, so you explain everything in sufficient detail. You're so good at programming that you have no equal. Write ONLY explanations in the form of comments. Be brief and concise. Explain.",
			user_promt = "%s; [CODE]: ```%s\n %s\n```",
			max_tokens = 4096,
			temperature = 0.5,
		},
	},
	class = {},
}

function M.setup(user_config)
	M.config = vim.tbl_deep_extend("force", M.default_config, user_config or {})
end

function M.get_config()
	return M.config
end

return M
