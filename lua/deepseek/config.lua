local M = {}

M.default_config = {
	config = {
		order = 0,
		disable = true,
	},
	commands = {
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
		stream_timeout = "30",
	},
	keymaps = {
		order = 99,
		generate = "<leader>ag",
		optimize = "<leader>ao",
		analyze = "<leader>aa",
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
			loader_prefix = "AI готовит ответ ",
			loader_postfix = "",
			load_success = "AI ответ готов!",
		},
		window = {
			default_position = "float", -- float, left, right, top, bottom
			width = 0.7, -- float window width ratio
			height = 0.6, -- float window height ratio
			min_width = 15, -- минимальная ширина окна чата
			min_height = 15, -- минимальная высота окна чата
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
			model = "deepseek-chat",
			system_prompt = "Ты — AI ассистент помогающий по %s языку программирвоания",
			max_history = 10,
			enable_memory = true,
			hi_message = {
				"┌───────────────────────────────────────────────────────┐",
				"│           Добро пожаловать в Deepseek чат!            │",
				"│  Insert-mode: <C-i>   для отправки, <C-q> для выхода  │",
				"│  Normal-mode: <Enter> для отправки,   q   для выхода  │",
				"│               Приятного использования                 │",
				"└───────────────────────────────────────────────────────┘",
			},
		},
		translate = {
			model = "deepseek-chat",
			system_prompt = "Ты — переводчик. Ты получаешь текст и переводишь его на %s язык. Твой ответ должен содержать только перевод, без пояснений. Если текст уже на нужном языке, возвращай перевод на %s языке. Не добавляй кавычки, если они не были в исходном сообщении, оставляй отступы и спец. символы в начале строк если они были в исходном сообщении.",
			language = "English",
			second_language = "Russian",
			max_tokens = 4096,
			temperature = 1.5,
			enable_memory = false,
		},
		improve = {
			model = "deepseek-chat",
			system_prompt = "Отвечай только исправленным текстом, без вводных слов, пояснений и завершающих фраз. Не пиши: 'Вот исправленный текст', 'Как ты просил', 'Если нужна помощь' и т. п. Просто сразу возвращай улучшенную версию текста.",
			max_tokens = 4096,
			temperature = 0.7,
			enable_memory = false,
		},
	},
	class = {},

	generate_code = {
		model = "deepseek-chat",
		system_prompt = "Ты — senior %s-разработчик. У тебя нет времени на приветсвтие и вежливости, но ты шикарно умеешь программировать. Пиши ТОЛЬКО код. Будь краток и лаконичен. Объясняй только если попросят.",
		max_tokens = 2048,
		temperature = 0.0,
	},
	optimize_code = {
		model = "deepseek-chat",
		system_prompt = "Ты — senior %s-разработчик. У тебя нет времени на приветсвтие и вежливости, но ты шикарно умеешь программировать. Пиши ТОЛЬКО код. Будь краток и лаконичен. Объясняй только если попросят.",
		max_tokens = 4096,
		temperature = 0.2,
	},
	analyze_code = {
		model = "deepseek-chat",
		system_prompt = "Ты — senior %s-разработчик. Ты желаешь научить новичка программировать, поэтому достаточно подробно разъесняешь все, ты настолько хорошо разбираешься в программировании что тебе нет равных. Пиши ТОЛЬКО пояснения. Будь краток и лаконичен. Объясняй.",
		user_promt = "Вопрос: %s; мой код %s",
		max_tokens = 4096,
		temperature = 0.5,
	},
}

function M.setup(user_config)
	M.config = vim.tbl_deep_extend("force", M.default_config, user_config or {})
end

function M.get_config()
	return M.config
end

return M
