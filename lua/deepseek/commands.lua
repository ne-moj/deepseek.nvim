local M = {}
local config = require("deepseek.config")
local api = require("deepseek.api")
local commane_api = require("Comment.api")

function M.setup()
	local cfg = config.get_config()

	-- Translate command
	vim.api.nvim_create_user_command("DeepseekTranslate", function()
		local translate_text = table.concat(get_visual_selection(), "\n")
		local response = api.translate_code(translate_text, cfg.translate_code)
		if response and response.choices and response.choices[1] then
			local lines = vim.split(response.choices[1].message.content, "\n")
			-- Inserting
			print_content_to_visual_selection(lines)
		end
	end, { range = true })

	-- Generate command
	vim.api.nvim_create_user_command("DeepseekGenerate", function(opts)
		local prompt = table.concat(opts.fargs, " ")
		local response = api.generate_code(prompt, cfg.generate_code)
		if response and response.choices and response.choices[1] then
			local lines = prepare_output(response.choices[1].message.content)
			-- Вставляем
			vim.api.nvim_put(lines, "c", true, true)
		end
	end, { nargs = "*" })

	-- Optimize command
	vim.api.nvim_create_user_command("DeepseekOptimize", function()
		local code = table.concat(get_visual_selection(), "\n")
		local response = api.optimize_code(code, cfg.optimize_code)
		if response and response.choices and response.choices[1] then
			local lines = prepare_output(response.choices[1].message.content)
			-- Вставляем
			print_content_to_visual_selection(lines)
			vim.api.nvim_buf_set_lines(bufnr, start_pos - 1, end_pos, false, lines)
		end
	end, { range = true })

	-- Analyze command
	vim.api.nvim_create_user_command("DeepseekAnalyze", function(opts)
		local prompt = table.concat(opts.fargs, " ")

		local code = table.concat(get_visual_selection(), "\n")
		local response = api.analyze_code(prompt, code, cfg.analyze_code)
		if response and response.choices and response.choices[1] then
			local lines = prepare_output(response.choices[1].message.content)
			-- 1. Получаем строку перед вставкой
			local row_before = vim.api.nvim_win_get_cursor(0)[1]
			-- 2. Вставляем строки
			vim.api.nvim_put(lines, "l", false, true)
			-- 3. Получаем строку после вставки
			local row_after = vim.api.nvim_win_get_cursor(0)[1]
			-- 4. Закомментируем вставленные строки
			commane_api.locked("toggle.linewise")(row_before, row_after - 1)
		end
	end, { range = true })

	-- Chat command
	vim.api.nvim_create_user_command("DeepseekChat", function(opts)
		local cfg = config.get_config()

		local prompt = table.concat(opts.fargs, " ")

		-- 创建主聊天窗口
		local chat_width = math.floor(vim.o.columns * cfg.chat.ui.width)
		local chat_height = math.floor(vim.o.lines * cfg.chat.ui.height * 0.8)

		if not M.chat_buf then
			M.chat_buf = vim.api.nvim_create_buf(false, true)
		end
		M.chat_win = vim.api.nvim_open_win(M.chat_buf, true, {
			relative = "editor",
			width = chat_width,
			height = chat_height,
			col = (vim.o.columns - chat_width) / 2,
			row = (vim.o.lines - chat_height) / 2 - 10,
			style = "minimal",
			border = {
				{ "🭽", "FloatBorder" },
				{ "▔", "FloatBorder" },
				{ "🭾", "FloatBorder" },
				{ "▕", "FloatBorder" },
				{ "🭿", "FloatBorder" },
				{ "▁", "FloatBorder" },
				{ "🭼", "FloatBorder" },
				{ "▏", "FloatBorder" },
			},
			title = " Deepseek Chat ",
			title_pos = "center",
		})

		-- 设置高亮组
		vim.api.nvim_set_hl(0, "DeepseekUser", { fg = "#569CD6", bold = true })
		vim.api.nvim_set_hl(0, "DeepseekAI", { fg = "#4EC9B0", bold = true })
		vim.api.nvim_set_hl(0, "DeepseekTimestamp", { fg = "#6B737F", italic = true })

		-- 创建输入窗口
		local input_width = chat_width
		local input_height = 3
		if not M.input_buf then
			M.input_buf = vim.api.nvim_create_buf(false, true)
		end
		M.input_win = vim.api.nvim_open_win(M.input_buf, true, {
			relative = "editor",
			width = input_width,
			height = input_height,
			col = (vim.o.columns - input_width) / 2,
			row = (vim.o.lines - input_height) / 2 + chat_height / 2 - 5,
			style = "minimal",
			border = cfg.chat.ui.border,
		})

		-- 设置窗口选项
		vim.api.nvim_win_set_option(M.chat_win, "wrap", true)
		vim.api.nvim_win_set_option(M.chat_win, "number", false)
		vim.api.nvim_win_set_option(M.chat_win, "relativenumber", false)

		-- 输入窗口映射
		vim.api.nvim_buf_set_keymap(
			M.input_buf,
			"n",
			"<CR>",
			[[<Cmd>lua require("deepseek.commands").send_chat()<CR>]],
			{ noremap = true, silent = true }
		)
		vim.api.nvim_buf_set_keymap(
			M.input_buf,
			"i",
			"<CR>",
			[[<Cmd>lua require("deepseek.commands").send_chat()<CR>]],
			{ noremap = true, silent = true }
		)
		vim.api.nvim_buf_set_keymap(
			M.input_buf,
			"n",
			"<Esc>",
			[[<Cmd>lua require("deepseek.commands").close_chat()<CR>]],
			{ noremap = true, silent = true }
		)
		vim.api.nvim_buf_set_keymap(
			M.input_buf,
			"i",
			"<Esc>",
			[[<Cmd>lua require("deepseek.commands").close_chat()<CR>]],
			{ noremap = true, silent = true }
		)

		-- 设置初始提示
		vim.api.nvim_buf_set_lines(M.chat_buf, 0, -1, false, {
			" ",
			"┌──────────────────────────────────────────────┐",
			"│  Welcome to Deepseek Chat!                   │",
			"│  Type your message below and press Enter     │",
			"│  to send. Press Esc to close the window.     │",
			"└──────────────────────────────────────────────┘",
			" ",
		})

		if prompt then
			vim.api.nvim_buf_set_lines(M.input_buf, 0, -1, false, { prompt })
			M.send_chat()
		end
	end, { nargs = "*" })

	function M.send_chat()
		local cfg = config.get_config()
		local lines = vim.api.nvim_buf_get_lines(M.input_buf, 0, -1, false)
		local prompt = table.concat(lines, "\n")

		-- 清空输入框
		vim.api.nvim_buf_set_lines(M.input_buf, 0, -1, false, { "" })

		-- 添加时间戳
		local timestamp = os.date("%H:%M")

		-- 添加用户消息到聊天窗口
		vim.api.nvim_buf_set_lines(M.chat_buf, -1, -1, false, {
			" ",
			" " .. timestamp,
			" You",
			" ",
			prompt,
			" ",
			"──────────────────────────────────────────────",
		})

		-- 获取响应
		local response = api.chat(prompt, cfg)
		if response and response.choices and response.choices[1] then
			local content = response.choices[1].message.content
			local timestamp = os.date("%H:%M")
			local content_lines = type(content) == "string" and vim.split(content, "\n", { plain = true }) or content

			vim.api.nvim_buf_set_lines(
				M.chat_buf,
				-1,
				-1,
				false,
				vim.list_extend(
					vim.list_extend({
						" ",
						" " .. timestamp,
						" Deepseek",
						" ",
					}, content_lines),
					{
						" ",
						"──────────────────────────────────────────────",
					}
				)
			)
		end

		-- 滚动到底部
		vim.api.nvim_win_set_cursor(M.chat_win, { vim.api.nvim_buf_line_count(M.chat_buf), 0 })
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

function prepare_output(content)
	-- Убираем обёртку ```javascript(или нечто похожее) и```
	local cleaned = content:gsub("^```.-\n", ""):gsub("```$", "")
	-- Превращаем \n в реальные переносы строк
	local unescaped = cleaned:gsub("\\n", "\n")
	-- Разбиваем строку на массив строк
	return vim.split(unescaped, "\n")
end

function print_content_to_visual_selection(lines)
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

local function safe_substring(line, start_col, end_col)
	local utf8_len = vim.fn.strchars(line) -- Количество UTF-8 символов

	-- Adjusting the range if it goes beyond the row boundariesи
	if start_col > utf8_len then
		start_col = utf8_len
	end
	if end_col > utf8_len then
		end_col = utf8_len
	end

	-- Converting to byte indices (important: -1, because str_byteindex works with 0-based indexing))
	local start_byte = vim.str_byteindex(line, start_col)
	local end_byte = vim.str_byteindex(line, end_col)

	return string.sub(line, start_byte + 1, end_byte)
end

function get_visual_selection()
	local bufnr = vim.api.nvim_get_current_buf()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	local start_line = start_pos[2] - 1
	local start_col = start_pos[3] - 1
	local end_line = end_pos[2] - 1
	local end_col = end_pos[3] - 1

	local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)

	if #lines == 1 then
		lines[1] = safe_substring(lines[1], start_col, end_col)
	else
		lines[1] = safe_substring(lines[1], start_col, #lines[1])
		lines[#lines] = safe_substring(lines[#lines], 0, end_col)
	end

	return lines
end

return M
