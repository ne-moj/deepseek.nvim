local M = {}

local config = require("deepseek.config")
local api = require("deepseek.api")

local strings = require("plenary.strings")
local commane_api = require("Comment.api")

M.chat_buf = nil
M.chat_win = nil
M.input_buf = nil
M.input_win = nil
M.loader_running = nil

function M.setup()
	local cfg = config.get_config()

	-- Translate command
	vim.api.nvim_create_user_command("DeepseekTranslate", function()
		local vis = M.get_last_visula_selection()
		local selection = M.get_visual_selection(vis)
		local translate_text = nil
		if type(selection) == "table" then
			translate_text = table.concat(selection, "\n")
		else
			-- На всякий случай, если вернётся что-то странное
			translate_text = tostring(selection)
		end

		print(translate_text)

		api.translate_code(translate_text, cfg.translate_code, function(response)
			if response and response.choices and response.choices[1] then
				local lines = vim.split(response.choices[1].message.content, "\n")
				-- Inserting
				M.print_content_to_visual_selection(lines, vis)
			end
		end)
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
		local vis = M.get_last_visula_selection()
		local code = table.concat(M.get_visual_selection(vis), "\n")
		local response = api.optimize_code(code, cfg.optimize_code)
		if response and response.choices and response.choices[1] then
			local lines = M.prepare_output(response.choices[1].message.content)
			-- Вставляем
			M.print_content_to_visual_selection(lines, vis)
		end
	end, { range = true })

	-- Analyze command
	vim.api.nvim_create_user_command("DeepseekAnalyze", function(opts)
		local vis = M.get_last_visula_selection()
		local prompt = table.concat(opts.fargs, " ")

		local code = table.concat(M.get_visual_selection(vis), "\n")
		local response = api.analyze_code(prompt, code, cfg.analyze_code)
		if response and response.choices and response.choices[1] then
			local lines = M.prepare_output(response.choices[1].message.content)
			vim.api.nvim_put(lines, "l", false, true)
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
			" ",
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
		vim.cmd("stopinsert")
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

function M.print_content_to_visual_selection(lines, vis)
	if not vis then
		vis = M.get_last_visula_selection()
	end

	-- Проверяем, что строки существуют
	if not vim.api.nvim_buf_is_valid(vis.bufnr) then
		return
	end

	if vis.mode == "V" or vis.mode == "v" then
		local line_count = vim.api.nvim_buf_line_count(vis.bufnr)
		local set_end_col = vis.end_col + 1

		if vis.start_line >= line_count then
			vis.start_line = line_count - 1
		end
		if vis.end_line >= line_count then
			vis.end_line = line_count - 1
		end

		-- Получаем строки и их длину в байтах
		local start_line = vim.api.nvim_buf_get_lines(vis.bufnr, vis.start_line, vis.start_line + 1, false)[1] or ""
		local end_line = vim.api.nvim_buf_get_lines(vis.bufnr, vis.end_line, vis.end_line + 1, false)[1] or ""

		local start_col_max = #start_line
		local end_col_max = #end_line

		if vis.start_col > start_col_max then
			vis.start_col = start_col_max
		end
		if set_end_col > end_col_max then
			set_end_col = end_col_max
		end

		-- Вызываем безопасную вставку
		vim.api.nvim_buf_set_text(vis.bufnr, vis.start_line, vis.start_col, vis.end_line, set_end_col, lines)
	elseif vis.mode == "\22" then
		local start_line = math.min(vis.start_line, vis.end_line)
		local end_line = math.max(vis.start_line, vis.end_line)
		local start_col = math.min(vis.start_col, vis.end_col)
		local end_col = math.max(vis.start_col, vis.end_col)

		-- Блочное выделение (<C-v>)
		for i = start_line, end_line do
			local line = vim.api.nvim_buf_get_lines(vis.bufnr, i, i + 1, false)[1] or ""
			local width = vim.fn.strchars(line)
			-- Ограничиваем колонку по длине строки
			local s_col = math.min(start_col, width)
			local e_col = math.min(end_col, width)
			local before = vim.fn.strcharpart(line, 0, s_col)
			local after = vim.fn.strcharpart(line, e_col)

			local insert_text = lines[(i - start_line) + 1] or ""
			local new_line = before .. insert_text .. after

			vim.api.nvim_buf_set_lines(vis.bufnr, i, i + 1, false, { new_line })
		end
	end
end

function M.get_visual_selection(vis)
	if not vis then
		vis = M.get_last_visula_selection()
	end

	local lines = vim.api.nvim_buf_get_lines(vis.bufnr, vis.start_line, vis.end_line + 1, false)

	if vis.mode == "v" then -- Символьное выделение
		if #lines == 1 then
			return vim.fn.strcharpart(lines[1], vis.start_col, vis.end_col - vis.start_col)
		else
			lines[1] = vim.fn.strcharpart(lines[1], vis.start_col)
			lines[#lines] = vim.fn.strcharpart(lines[#lines], 0, vis.end_col)
			return lines
		end
	elseif vis.mode == "V" then -- Построчное выделение
		return lines
	elseif vis.mode == "\22" then -- Блочное выделение (<C-v>)
		local block_selection = {}
		for _, line in ipairs(lines) do
			local width = vim.fn.strchars(line)
			-- Ограничиваем колонки по длине строки
			local s_col = math.min(vis.start_col, width)
			local e_col = math.min(vis.end_col, width)
			local text = vim.fn.strcharpart(line, s_col, e_col - s_col)
			table.insert(block_selection, text)
		end
		return block_selection
	end

	return ""
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
	height = height >= 12 and height or 12
	width = width >= 12 and width or 12
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
		input_width = width

		input_row = vim.o.lines - input_height - 2

		opts = {
			relative = "editor",
			width = width,
			height = height,
			col = 0,
			row = (position == "bottom") and ((vim.o.lines - height) - 9) or 0,
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

	vim.api.nvim_buf_set_keymap(
		M.chat_buf,
		"n",
		"q",
		[[<Cmd>lua require("deepseek.commands").close_chat()<CR>]],
		{ noremap = true, silent = true }
	)

	vim.api.nvim_buf_set_keymap(
		M.input_buf,
		"n",
		"q",
		[[<Cmd>lua require("deepseek.commands").close_chat()<CR>]],
		{ noremap = true, silent = true }
	)

	vim.api.nvim_buf_set_keymap(
		M.chat_buf,
		"i",
		"<C-q>",
		[[<Cmd>lua require("deepseek.commands").close_chat()<CR>]],
		{ noremap = true, silent = true }
	)

	vim.api.nvim_buf_set_keymap(
		M.input_buf,
		"i",
		"<C-q>",
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

function M.get_last_visula_selection()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	return {
		start_line = start_pos[2] - 1,
		start_col = start_pos[3] - 1,
		end_line = end_pos[2] - 1,
		end_col = end_pos[3] - 1,
		bufnr = vim.api.nvim_get_current_buf(),
		mode = vim.fn.visualmode(),
	}
end

return M
