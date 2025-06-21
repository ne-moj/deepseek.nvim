local LOG = require("deepseek.log")
local class = require("deepseek.class")
local api = require("deepseek.api")
local loader = require("deepseek.ui.loader")

local BaseCommand = class()

BaseCommand.cfg = {}
BaseCommand.messages = {}
BaseCommand.history = {}
BaseCommand.last_stream_message = ""
BaseCommand.model = "deepseek-chat"
BaseCommand.max_tokens = 2048
BaseCommand.temperature = 0.7
BaseCommand.endpoint = "/chat/completions"
BaseCommand.max_history = 10
BaseCommand.show_loader = true
BaseCommand.stream_mode = false
BaseCommand.uuid_requests = {}

function BaseCommand:init() end

function BaseCommand:setup(cfg)
	self.cfg = cfg

	if self.cfg then
		self.model = self.cfg.model or self.model
		self.max_tokens = self.cfg.max_tokens or self.max_tokens
		self.temperature = self.cfg.temperature or self.temperature
		self.endpoint = self.cfg.endpoint or self.endpoint
		self.max_history = self.cfg.max_history or self.max_history
		self.show_loader = self.cfg.show_loader or self.show_loader
		self.stream_mode = self.cfg.stream_mode or self.stream_mode
	end
end

function BaseCommand:run(input, uuid)
	if not uuid then
		uuid = self:simple_guid()
	end

	self:before_send(input, uuid)
	self:update_system_params(uuid)
	local params = self:build_params(input, uuid)
	self:show_loader(uuid)
	if self.stream_mode then
		self:stream_request(uuid, params)
	else
		self:request(uuid, params)
	end
end

function BaseCommand:stream_request(uuid, params)
	self.last_stream_message = ""
	api.stream_request(params, function(chunk)
		self:get_stream_chunk(chunk, uuid)
	end, function()
		self:hide_loader(uuid)
		self:end_stream(uuid)
	end, self.endpoint)
end

function BaseCommand:request(uuid, params)
	api.request(params, function(response)
		self:hide_loader(uuid)
		self:get_response(response, uuid)
	end, self.endpoint)
end

function BaseCommand:show_loader(uuid)
	loader.show()
end

function BaseCommand:hide_loader(uuid)
	loader.hide()
end

function BaseCommand:before_send(input, uuid)
	-- переопределяется в дочерних методах
	vim.print("User: " .. input)
end

function BaseCommand:update_system_params(uuid)
	-- переопределяется в дочерних методах если нужно что-то подправить перед отправкой
	-- self.model = 'deepseek-chat'
	-- self.max_tokens = 2048
	-- self.temperature = 0.7
end

function BaseCommand:build_params(input, uuid)
	-- Подготавливаем параметры для отправки на сервер AI
	self.messages = {}
	self:build_system_prompt(uuid)
	if self.cfg.enable_memory and #self.history > 0 then
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
		stream = self.stream_mode,
	}
end

function BaseCommand:build_system_prompt(uuid)
	-- переопределяется в дочерних методах
	-- Формируем системный промт
	if self.cfg and self.cfg.system_prompt then
		table.insert(self.messages, { role = "system", content = (self.cfg.system_prompt):format(vim.bo.filetype) })
	end
end

function BaseCommand:get_stream_chunk(chunk, uuid)
	LOG:TRACE(chunk)
	if chunk and chunk.choices and chunk.choices[1] and chunk.choices[1].delta and chunk.choices[1].delta.content then
		self.last_stream_message = self.last_stream_message .. chunk.choices[1].delta.content
		-- Печатаем ответ от AI
		self:print_ai_chunk(chunk.choices[1].delta.content, uuid)
	end
end

function BaseCommand:end_stream(uuid)
	if self.cfg.enable_memory then
		table.insert(self.history, {
			role = "assistant",
			content = self.last_stream_message,
		})
	end
end

function BaseCommand:get_response(response, uuid)
	if
		response
		and response.choices
		and response.choices[1]
		and response.choices[1].message
		and response.choices[1].message.content
	then
		if self.cfg.enable_memory then
			table.insert(self.history, {
				role = "assistant",
				content = response.choices[1].message.content,
			})
		end
		-- Печатаем ответ от AI
		self:print_ai_response(response.choices[1].message.content, uuid)
	end

	if self.cfg.enable_memory then
		-- Чистим историю чата
		while #self.history > self.max_history do
			table.remove(self.history, 1)
		end
	end
end

function BaseCommand:print_ai_chunk(chunk, uuid)
	-- переопределяется в дочерних методах
	LOG:TRACE(chunk)
end

function BaseCommand:print_ai_response(response, uuid)
	-- переопределяется в дочерних методах
	LOG:DEBUG("Сработала заглушка - сообщение пришло.")
	LOG:TRACE("AI: " .. response)
end

function BaseCommand:simple_guid()
	local time = os.time()
	local random = math.random(0, 65535)
	return string.format("%x-%x", time, random)
end

return BaseCommand
