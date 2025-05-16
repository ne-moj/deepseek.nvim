local M = {}

local api_key = nil
local api_url = "https://api.deepseek.com/v1"

function M.setup(cfg)
	api_key = cfg.api_key
	if cfg.api_url then
		api_url = cfg.api_url
	end
end

local function make_request(endpoint, params)
	local body = vim.fn.json_encode(params)
	local response = vim.fn.system({
		"curl",
		"-s",
		"-X",
		"POST",
		"-H",
		"Content-Type: application/json",
		"-H",
		"Accept: application/json",
		"-H",
		"Authorization: Bearer " .. api_key,
		"--data-raw",
		body,
		api_url .. endpoint,
	})

	return vim.fn.json_decode(response)
end

local function make_request_async(endpoint, params, callback)
	local body = vim.fn.json_encode(params)
	local args = {
		"-s",
		"-X",
		"POST",
		"-H",
		"Content-Type: application/json",
		"-H",
		"Accept: application/json",
		"-H",
		"Authorization: Bearer " .. api_key,
		"--data-raw",
		body,
		api_url .. endpoint,
	}

	local stdout = vim.uv.new_pipe(false)
	local stderr = vim.uv.new_pipe(false)

	vim.uv.spawn("curl", { args = args, stdio = { nil, stdout, stderr } }, function()
		vim.uv.read_stop(stdout)
		vim.uv.read_stop(stderr)
		vim.uv.close(stdout)
		vim.uv.close(stderr)
	end)

	local data = ""

	vim.uv.read_start(stdout, function(err, chunk)
		assert(not err, err)
		if chunk then
			data = data .. chunk
		else
			-- Завершение запроса, вызываем коллбэк
			vim.schedule(function()
				local json = vim.fn.json_decode(data)
				callback(json)
			end)
		end
	end)
end

function M.translate_code(prompt, cfg)
	local messages = {}
	table.insert(messages, { role = "system", content = (cfg.system_prompt):format(cfg.language, cfg.second_language) })
	table.insert(messages, { role = "user", content = prompt })

	local params = {
		model = cfg.model,
		messages = messages,
		max_tokens = cfg.max_token,
		temperature = cfg.temperature,
	}

	return make_request("/chat/completions", params)
end

function M.generate_code(prompt, cfg)
	local messages = {}
	table.insert(messages, { role = "system", content = (cfg.system_prompt):format(vim.bo.filetype) })
	table.insert(messages, { role = "user", content = prompt })

	local params = {
		model = cfg.model,
		messages = messages,
		max_tokens = cfg.max_token,
		temperature = cfg.temperature,
	}

	return make_request("/chat/completions", params)
end

function M.optimize_code(code, cfg)
	local messages = {}
	table.insert(messages, { role = "system", content = (cfg.system_prompt):format(vim.bo.filetype) })
	table.insert(messages, { role = "user", content = code })

	local params = {
		model = cfg.model,
		messages = messages,
		max_tokens = cfg.max_token,
		temperature = cfg.temperature,
	}

	return make_request("/chat/completions", params)
end

function M.analyze_code(prompt, code, cfg)
	local messages = {}
	table.insert(messages, { role = "system", content = (cfg.system_prompt):format(vim.bo.filetype) })
	table.insert(messages, { role = "user", content = (cfg.user_promt):format(prompt, code) })

	local params = {
		model = cfg.model,
		messages = messages,
		max_tokens = cfg.max_token,
		temperature = cfg.temperature,
	}

	return make_request("/chat/completions", params)
end

-- 对话功能实现
local chat_history = {}

function M.chat(message, cfg, callback)
	-- 构建对话上下文
	local messages = {}
	if cfg.chat.enable_memory and #chat_history > 0 then
		table.insert(messages, { role = "system", content = (cfg.chat.system_prompt):format(vim.bo.filetype) })
		for _, msg in ipairs(chat_history) do
			table.insert(messages, msg)
		end
	end
	table.insert(messages, { role = "user", content = message })

	-- 发送请求
	local params = {
		model = cfg.chat.model,
		messages = messages,
		max_tokens = cfg.max_tokens,
		temperature = cfg.temperature,
	}

	make_request_async("/chat/completions", params, function(response)
		-- 更新对话历史
		if cfg.chat.enable_memory then
			table.insert(chat_history, { role = "user", content = message })
			if response and response.choices and response.choices[1] then
				table.insert(chat_history, {
					role = "assistant",
					content = response.choices[1].message.content,
				})
			end
			-- Чистим историю чата
			while #chat_history > cfg.chat.max_history do
				table.remove(chat_history, 1)
			end
		end

		callback(response)
	end)
end

return M
