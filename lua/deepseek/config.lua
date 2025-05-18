local M = {}

M.default_config = {
	config = {
		order = 0,
		disable = true,
	},
	commands = {
		disable = true,
	},
	api = {
		order = 1,
		key = nil,
		url = "https://api.deepseek.com/v1",
		default_model = "deepseek-chat",
	},
	keymaps = {
		order = 99,
		generate = "<leader>ag",
		optimize = "<leader>ao",
		analyze = "<leader>aa",
		translate = "<leader>at",
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
		loader = {
			loader_prefix = "AI готовит ответ ",
			loader_postfix = "",
			load_success = "AI ответ готов!",
		},
		order = 10,
		default_position = "float", -- float, left, right, top, bottom
		width = 0.5, -- float window width ratio
		height = 0.5, -- float window height ratio
		min_width = 12, -- минимальная ширина окна чата
		min_height = 12, -- минимальная высота окна чата
		border = "rounded", -- window border style
	},
	core = {
		order = 60,
		model = "deepseek-chat",
		base_command = {
			order = 1,
			enable_memory = true,
		},
	},
	class = {},

	chat = {
		model = "deepseek-chat",
		system_prompt = "Ты — AI ассистент помогающий по %s языку программирвоания",
		max_history = 10,
		enable_memory = true,
	},
	translate_code = {
		model = "deepseek-chat",
		system_prompt = "Ты — переводчик. Ты получаешь текст и переводишь его на %s язык. Твой ответ должен содержать только перевод, без пояснений. Если текст уже на нужном языке, возвращай перевод на %s языке. Не добавляй кавычки, если они не были в исходном сообщении.",
		language = "English",
		second_language = "Russian",
		max_tokens = 4096,
		temperature = 0.2,
	},
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
