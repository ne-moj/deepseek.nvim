local M = {}

M.default_config = {
	api_key = nil, -- Required
	api_url = "https://api.deepseek.com/v1",
	api_code_model = "deepseek-reasoner",
	keymaps = {
		generate = "<leader>dg",
		optimize = "<leader>do",
		analyze = "<leader>da",
		chat = "<leader>dc", -- 新增对话快捷键
	},
	max_tokens = 2048,
	temperature = 0.7,
	enable_ui = true,
	chat = {
		system_prompt = "You are a helpful AI assistant",
		max_history = 10,
		enable_memory = true,
		ui = {
			enable = true,
			position = "float", -- or "right"
			width = 0.5, -- float window width ratio
			height = 0.5, -- float window height ratio
			border = "rounded", -- window border style
		},
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
		max_tokens = 2048,
		temperature = 0.2,
	},
	analyze_code = {
		model = "deepseek-chat",
		system_prompt = "Ты — senior %s-разработчик. Ты желаешь научить новичка программировать, поэтому достаточно подробно разъесняешь все, ты настолько хорошо разбираешься в программировании что тебе нет равных. Пиши ТОЛЬКО пояснения. Будь краток и лаконичен. Объясняй.",
		user_promt = "Вопрос: %s; мой код %s",
		max_tokens = 2048,
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
