local M = {}
local config = require("deepseek.config")
local api = require("deepseek.api")
local commane_api = require("Comment.api")

M.buffers = {}
M.windows = {}
M.chat_buf = nil
M.chat_win = nil
M.input_buf = nil
M.input_win = nil
M.loader_running = nil

function M.setup()
	local cfg = config.get_config()

	-- Translate command
	vim.api.nvim_create_user_command("DeepseekTranslate", function()
		local translate_text = table.concat(M.get_visual_selection(), "\n")
		local response = api.translate_code(translate_text, cfg.translate_code)
		if response and response.choices and response.choices[1] then
			local lines = vim.split(response.choices[1].message.content, "\n")
			-- Inserting
			M.print_content_to_visual_selection(lines)
		end
	end, { range = true })

	-- Generate command
	vim.api.nvim_create_user_command("DeepseekGenerate", function(opts)
		local prompt = table.concat(opts.fargs, " ")
		local response = api.generate_code(prompt, cfg.generate_code)
		if response and response.choices and response.choices[1] then
			local lines = M.prepare_output(response.choices[1].message.content)
			-- Вставляем
			vim.api.nvim_put(lines, "c", true, true)
		end
	end, { nargs = "*" })

	-- Optimize command
	vim.api.nvim_create_user_command("DeepseekOptimize", function()
		local code = table.concat(M.get_visual_selection(), "\n")
		local response = api.optimize_code(code, cfg.optimize_code)
		if response and response.choices and response.choices[1] then
			local lines = M.prepare_output(response.choices[1].message.content)
			-- Вставляем
			M.print_content_to_visual_selection(lines)
		end
	end, { range = true })

	-- Analyze command
	vim.api.nvim_create_user_command("DeepseekAnalyze", function(opts)
		local prompt = table.concat(opts.fargs, " ")

		local code = table.concat(M.get_visual_selection(), "\n")
		local response = api.analyze_code(prompt, code, cfg.analyze_code)
		if response and response.choices and response.choices[1] then
			local lines = M.prepare_output(response.choices[1].message.content)
			-- 1. Получаем строку перед вставкой
			local row_before = vim.api.nvim_win_get_cursor(0)[1]
			-- 2. Вставляем строки
			vim.api.nvim_put(lines, "l", false, true)
			-- 3. Получаем строку после вставки
			local row_after = vim.api.nvim_win_get_cursor(0)[1]
			-- 4. Закомментируем вставленные строки
			commane_api.locked("toggle.linewise")("line")
		end
	end, { range = true })

	-- Toggle-Chat command
	vim.api.nvim_create_user_command("DeepseekChat", function(opts)
		M.toggle_chat(opts.args)
	end, {
		nargs = "?",
		complete = function()
			return { "left", "right", "top", "bottom", "float" }
		end,
	})

	function M.send_chat()
		local lines = vim.api.nvim_buf_get_lines(M.input_buf, 0, -1, false)
		local prompt = table.concat(lines, "\n")

		-- 清空输入框
		vim.api.nvim_buf_set_lines(M.input_buf, 0, -1, false, { "" })

		-- 添加时间戳
		local timestamp = os.date("%H:%M")

		-- 添加用户消息到聊天窗口
		vim.api.nvim_buf_set_lines(M.chat_buf, -1, -1, false, {
			" ",
			"[" .. timestamp .. "] You: " .. prompt,
			" ",
			"──────────────────────────────────────────────",
		})

		M.start_loader()

		api.chat(prompt, cfg, function(response)
			M.stop_loader()
			if response and response.choices and response.choices[1] then
				local content = response.choices[1].message.content
				timestamp = os.date("%H:%M")
				local content_lines = type(content) == "string" and vim.split(content, "\n", { plain = true })
					or content

				vim.api.nvim_buf_set_lines(
					M.chat_buf,
					-1,
					-1,
					false,
					vim.list_extend(
						vim.list_extend({
							" ",
							"[" .. timestamp .. "] Deepseek: ",
						}, content_lines),
						{
							" ",
							"──────────────────────────────────────────────",
						}
					)
				)
			end

			vim.api.nvim_win_set_cursor(M.chat_win, { vim.api.nvim_buf_line_count(M.chat_buf), 0 })
		end)
	end

	function M.close_chat()
		vim.api.nvim_win_close(M.chat_win, true)
		vim.api.nvim_win_close(M.input_win, true)
	end

	-- Set up keymaps
	if cfg.keymaps then
		vim.keymap.set("n", cfg.keymaps.generate, ":DeepseekGenerate ", { noremap = true })
		vim.keymap.set("v", cfg.keymaps.optimize, ":DeepseekOptimize<CR>", { noremap = true })
		vim.keymap.set("v", cfg.keymaps.analyze, ":DeepseekAnalyze<CR>", { noremap = true })
		vim.keymap.set("v", cfg.keymaps.translate, ":DeepseekTranslate<CR>", { noremap = true })
		vim.keymap.set("n", cfg.keymaps.chat, ":DeepseekChat ", { noremap = true })
	end
end

function M.prepare_output(content)
	-- Убираем обёртку ```javascript(или нечто похожее) и```
	local cleaned = content:gsub("^```.-\n", ""):gsub("```$", "")
	-- Превращаем \n в реальные переносы строк
	local unescaped = cleaned:gsub("\\n", "\n")
	-- Разбиваем строку на массив строк
	return vim.split(unescaped, "\n")
end

function M.print_content_to_visual_selection(lines)
	local bufnr = vim.api.nvim_get_current_buf()

	-- Начало и конец выделения
	local start_pos = vim.fn.getpos("'<") -- {mark, line, col, offset}
	local end_pos = vim.fn.getpos("'>")

	local start_line = start_pos[2] - 1
	local start_col = start_pos[3] - 1
	local end_line = end_pos[2] - 1
	local end_col = end_pos[3]

	-- Подстраховка: Получаем длину последней строки выделения
	local end_line_text = vim.api.nvim_buf_get_lines(bufnr, end_line, end_line + 1, false)[1] or ""
	if end_col > #end_line_text then
		end_col = #end_line_text
	end

	vim.api.nvim_buf_set_text(bufnr, start_line, start_col, end_line, end_col, lines)
end

function M.safe_substring(line, start_col, end_col)
	local utf8_len = vim.fn.strchars(line) -- Количество UTF-8 символов

	-- Adjusting the range if it goes beyond the row boundariesи
	if start_col > utf8_len then
		start_col = utf8_len
	end
	if end_col > utf8_len then
		end_col = utf8_len
	end

	-- Converting to byte indices (important: -1, because str_byteindex works with 0-based indexing))
	local start_byte = vim.str_byteindex(line, "utf-8", start_col)
	local end_byte = vim.str_byteindex(line, "utf-8", end_col)

	return string.sub(line, start_byte + 1, end_byte)
end

function M.get_visual_selection()
	local bufnr = vim.api.nvim_get_current_buf()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	local start_line = start_pos[2] - 1
	local start_col = start_pos[3] - 1
	local end_line = end_pos[2] - 1
	local end_col = end_pos[3] - 1

	local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)

	if #lines == 1 then
		lines[1] = M.safe_substring(lines[1], start_col, end_col)
	else
		lines[1] = M.safe_substring(lines[1], start_col, #lines[1])
		lines[#lines] = M.safe_substring(lines[#lines], 0, end_col)
	end

	return lines
end

function M.toggle_chat(position)
	local cfg = config.get_config()
	position = position or "float"

	if M.chat_win and vim.api.nvim_win_is_valid(M.chat_win) then
		M.close_chat()
		return
	end

	if not M.chat_buf then
		M.chat_buf = vim.api.nvim_create_buf(false, true)

		vim.api.nvim_buf_set_lines(M.chat_buf, 0, -1, false, {
			" ",
			"┌──────────────────────────────────────────────┐",
			"│  Welcome to Deepseek Chat!                   │",
			"│  Type your message below and press Enter     │",
			"│  to send. Press Esc to close the window.     │",
			"└──────────────────────────────────────────────┘",
			" ",
		})
	end

	local width = math.floor(vim.o.columns * 0.5)
	local height = math.floor(vim.o.lines * 0.3)
	local col = 0

	local input_width = width
	local input_height = 5
	local input_col = col
	local input_row = height

	local opts = {}

	if position == "left" or position == "right" then
		width = math.floor(vim.o.columns * 0.3)
		input_width = width
		col = (position == "right") and (vim.o.columns - math.floor(vim.o.columns * 0.3)) or 0
		input_col = col

		height = vim.o.lines - 9
		input_row = height + 2
		opts = {
			relative = "editor",
			width = width,
			height = height,
			col = col,
			row = 0,
			style = "minimal",
			border = "single",
		}
	elseif position == "top" or position == "bottom" then
		width = vim.o.columns
		input_width = position == "top" and width or input_width

		input_col = position == "top" and 0 or ((vim.o.columns - input_width) / 2)
		input_row = position == "top" and height + 2 or ((vim.o.lines - height) / 2)

		opts = {
			relative = "editor",
			width = width,
			height = height,
			col = 0,
			row = (position == "bottom") and (vim.o.lines - height) or 0,
			style = "minimal",
			border = "single",
		}
	else -- float
		col = (vim.o.columns - width) / 2
		input_col = col
		input_row = height + 2 + ((vim.o.lines - height) / 2)
		opts = {
			relative = "editor",
			width = width,
			height = height,
			col = (vim.o.columns - width) / 2,
			row = (vim.o.lines - height) / 2,
			style = "minimal",
			border = "rounded",
			title = " Deepseek Chat ",
			title_pos = "center",
		}
	end

	if not M.input_buf then
		M.input_buf = vim.api.nvim_create_buf(false, true)
	end

	M.input_win = vim.api.nvim_open_win(M.input_buf, true, {
		relative = "editor",
		width = input_width,
		height = input_height,
		col = input_col,
		row = input_row,
		style = "minimal",
		border = cfg.chat.ui.border,
	})

	M.chat_win = vim.api.nvim_open_win(M.chat_buf, true, opts)

	vim.api.nvim_set_current_win(M.input_win)
	vim.api.nvim_set_current_buf(M.input_buf)

	-- set loader
	vim.defer_fn(function()
		local frames = { "|", "/", "-", "\\" }
		local idx = 1

		while M.loader_running do
			vim.api.nvim_buf_set_lines(M.chat_buf, -1, -1, false, { "AI: Loading " .. frames[idx] })
			idx = (idx % #frames) + 1
			vim.cmd("redraw")
			vim.wait(300) -- Подождём 300 мс перед сменой кадра
		end
	end, 0)

	-- Когда загрузка закончилась
	-- vim.api.nvim_buf_set_lines(M.buffers.chat, -1, -1, false, { "AI: ✅ Ответ получен!" })

	-- vim.keymap.set(
	-- 	{ "n", "i" },
	-- 	"<CR>",
	-- 	[[<Cmd>lua require("deepseek.commands").send_chat()<CR>]],
	-- 	{ buffer = M.chat_buf, noremap = true, silent = true }
	-- )
	vim.keymap.set(
		{ "n" },
		"<CR>",
		[[<Cmd>lua require("deepseek.commands").send_chat()<CR>]],
		{ buffer = M.input_buf, noremap = true, silent = true }
	)

	vim.keymap.set(
		{ "i" },
		"<C-i>",
		[[<Cmd>lua require("deepseek.commands").send_chat()<CR>]],
		{ buffer = M.input_buf, noremap = true, silent = true }
	)

	-- close window
	-- vim.api.nvim_buf_set_keymap(
	-- 	M.chat_buf,
	-- 	"n",
	-- 	"<Esc>",
	-- 	[[<Cmd>lua require("deepseek.commands").close_chat()<CR>]],
	-- 	{ noremap = true, silent = true }
	-- )
	vim.api.nvim_buf_set_keymap(
		M.chat_buf,
		"n",
		"q",
		[[<Cmd>lua require("deepseek.commands").close_chat()<CR>]],
		{ noremap = true, silent = true }
	)
	-- vim.api.nvim_buf_set_keymap(
	-- 	M.input_buf,
	-- 	"n",
	-- 	"<Esc>",
	-- 	[[<Cmd>lua require("deepseek.commands").close_chat()<CR>]],
	-- 	{ noremap = true, silent = true }
	-- )
	vim.api.nvim_buf_set_keymap(
		M.input_buf,
		"n",
		"q",
		[[<Cmd>lua require("deepseek.commands").close_chat()<CR>]],
		{ noremap = true, silent = true }
	)
end

function M.start_loader()
	local frames = { "|", "/", "-", "\\" }
	local idx = 1

	M.loader_running = true

	vim.schedule(function()
		local function animate()
			if not M.loader_running then
				return
			end

			-- Вставляем Loader символ
			vim.api.nvim_buf_set_lines(M.chat_buf, -2, -1, false, { "AI: Loading " .. frames[idx] })
			vim.cmd("redraw")

			idx = (idx % #frames) + 1

			-- Повторяем анимацию через 200 мс
			vim.defer_fn(animate, 200)
		end

		animate()
	end)
end

function M.stop_loader()
	M.loader_running = false
	vim.api.nvim_buf_set_lines(M.chat_buf, -2, -1, false, { "" })
end

return M
