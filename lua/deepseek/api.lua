local LOG = require("deepseek.log")
local Job = require("plenary.job")
local config = require("deepseek.config").get_config()

local M = {}

-- Функция для выполнения потокового HTTP-запроса
-- params - параметры запроса (тело запроса в формате таблицы Lua)
-- stream_callback - функция обратного вызова для обработки потоковых данных
-- end_callback - функция, вызываемая при завершении запроса
-- endpoint - конечная точка API (по умолчанию "/chat/completions")
function M.stream_request(params, stream_callback, end_callback, endpoint)
	local url = config.api.url .. (endpoint or "/chat/completions")
	Job:new({
		command = "curl",
		args = {
			"-s",
			"-m",
			tostring(config.api.stream_timeout or 0),
			url,
			"-N",
			"-X",
			"POST",
			"-H",
			"Content-Type: application/json",
			"-H",
			"Authorization: Bearer " .. config.api.key,
			"-d",
			vim.fn.json_encode(params),
		},
		on_stdout = vim.schedule_wrap(function(_, chunk)
			local decoded = {}
			if chunk and chunk:match("^data:%s*") then
				LOG:TRACE(chunk)
				local prepare_chunk = chunk:gsub("^data:%s*", "")
				if prepare_chunk and #prepare_chunk > 0 and prepare_chunk ~= "[DONE]" then
					decoded = vim.fn.json_decode(prepare_chunk)
				end
			end
			if decoded then
				stream_callback(decoded)
			end
		end),
		on_stderr = function(_, err)
			if err ~= nil then
				LOG:ERROR(err)
			end
		end,
		on_exit = vim.schedule_wrap(function()
			end_callback()
		end),
	}):start()
end

-- Функция для выполнения HTTP-запроса к API
-- params - параметры запроса (тело запроса)
-- callback - функция обратного вызова для обработки ответа
-- endpoint - конечная точка API (по умолчанию "/chat/completions")
function M.request(params, callback, endpoint)
	local url = config.api.url .. (endpoint or "/chat/completions")

	Job:new({
		command = "curl",
		args = {
			"-s",
			"-X",
			"POST",
			"-H",
			"Content-Type: application/json",
			"-H",
			"Authorization: Bearer " .. config.api.key,
			"--data-raw",
			vim.fn.json_encode(params),
			url,
		},
		on_exit = function(j)
			local result = table.concat(j:result(), "\n")
			vim.schedule(function()
				local decoded = {}
				if result then
					decoded = vim.fn.json_decode(result)
				end
				callback(decoded)
			end)
		end,
	}):start()
end

return M
