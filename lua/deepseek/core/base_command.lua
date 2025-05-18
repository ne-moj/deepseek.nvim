local class = require("deepseek.class")
local api = require("deepseek.api")
local ui = require("deepseek.ui.window")
local loader = require("deepseek.ui.loader")

local BaseCommand = class()

BaseCommand.cfg = {}
BaseCommand.messages = {}
BaseCommand.history = {}
BaseCommand.model = "deepseek-chat"
BaseCommand.max_tokens = 2048
BaseCommand.temperature = 0.7
BaseCommand.endpoint = "/chat/completions"
BaseCommand.max_history = 10

function BaseCommand:init() end

function BaseCommand:setup(opts)
	self.cfg = opts
end

function BaseCommand:run(input)
	self:befor_send(input)
	local params = self:build_params(input)
	loader.show()
	api.request(params, function(response)
		loader.hide()
		self:get_response(response)
	end, self.endpoint)
end

function BaseCommand:befor_send(input)
	-- Тут делаем необходмые действия до отправки
	ui.clear_input_buf()
	-- Печатаем в буфер чата сообщение пользователя
	ui.print_user_request(input)
end

function BaseCommand:build_params(input)
	-- Подготавливаем параметры для отправки на сервер AI
	if self.cfg.enable_memory and #self.history > 0 then
		self:build_system_prompt()
		for _, msg in ipairs(self.history) do
			table.insert(self.messages, msg)
		end
	end
	table.insert(self.messages, { role = "user", content = input })
	table.insert(self.history, { role = "user", content = input })

	return {
		model = self.model,
		messages = self.messages,
		max_tokens = self.max_tokens,
		temperature = self.temperature,
	}
end

function BaseCommand:build_system_prompt()
	-- Формируем системный промт
	table.insert(self.messages, { role = "system", content = (self.cfg.system_prompt):format(vim.bo.filetype) })
end

function BaseCommand:get_response(response)
	if response and response.choices and response.choices[1] then
		table.insert(self.history, {
			role = "assistant",
			content = response.choices[1].message.content,
		})
		-- Печатаем в буфер чата ответ от AI
		ui.print_ai_response(response.choices[1].message.content)
	end
	-- Чистим историю чата
	while #self.history > self.max_history do
		table.remove(self.history, 1)
	end
end

return BaseCommand
