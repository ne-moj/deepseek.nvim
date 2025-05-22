local buffer = require("deepseek.ui.buffer")
local M = {}

local position = "float"
local cfg = {}
local chat_win = nil
local input_win = nil

M.chat_buf = nil
M.input_buf = nil

function M.setup(opts)
	cfg = opts or {}
end

function M.create_input_buf()
	if not M.input_buf then
		M.input_buf = vim.api.nvim_create_buf(false, true)
	end
end

function M.create_chat_buf(first_msg)
	if not M.chat_buf then
		if not first_msg then
			first_msg = {
				" ",
				"┌──────────────────────────────────────────────┐",
				"│  Welcome to Deepseek Chat!                   │",
				"│  Type your message below and press Enter     │",
				"│  to send. Press Esc to close the window.     │",
				"└──────────────────────────────────────────────┘",
				" ",
			}
		end

		M.chat_buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(M.chat_buf, 0, -1, false, first_msg)
	end
end

function M.set_position(pos)
	position = pos
end

function M.close_chat()
	if chat_win then
		vim.api.nvim_win_close(chat_win, true)
	end
	if input_win then
		vim.api.nvim_win_close(input_win, true)
	end

	vim.cmd("stopinsert")
end

function M.show_popup()
	M.close_chat()
	M.toggle_popup()
end

function M.toggle_popup()
	if chat_win and vim.api.nvim_win_is_valid(chat_win) then
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

	local width = math.floor(vim.o.columns * (cfg.width or 0.5))
	local height = math.floor(vim.o.lines * (cfg.height or 0.3))
	local min_height = cfg.min_height or 12
	local min_width = cfg.min_width or 12
	local style = cfg.style or "minimal"
	local border = cfg.border or "single"
	local input_height = cfg.input_height or 5

	height = height >= min_height and height or min_height
	width = width >= min_width and width or min_width

	local col = 0

	local input_width = width
	local input_col = col
	local input_row = height

	local opts = {}

	if position == "left" or position == "right" then
		width = math.floor(vim.o.columns * 0.3)
		input_width = width

		col = (position == "right") and (vim.o.columns - math.floor(vim.o.columns * 0.3)) or 0
		input_col = col

		height = vim.o.lines - (input_height + 4)
		input_row = height + 2
		opts = {
			relative = "editor",
			width = width,
			height = height,
			col = col,
			row = 0,
			style = style,
			border = position == "left" and cfg.left_border or cfg.right_border or border,
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
			row = (position == "bottom") and ((vim.o.lines - height) - (input_height + 4)) or 0,
			style = position == "top" and cfg.top_style or cfg.bottom_style or style,
			border = position == "top" and cfg.top_border or cfg.bottom_border or border,
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
			style = cfg.float_style or style,
			border = cfg.float_border or border,
			title = cfg.float_title or " Deepseek Chat ",
			title_pos = cfg.float_title_pos or "center",
		}
	end

	M.create_input_buf()

	input_win = vim.api.nvim_open_win(M.input_buf, true, {
		relative = "editor",
		width = input_width,
		height = input_height,
		col = input_col,
		row = input_row,
		style = cfg.input_style or "minimal",
		border = cfg.input_border or "single",
	})

	chat_win = vim.api.nvim_open_win(M.chat_buf, true, opts)

	vim.api.nvim_set_current_win(input_win)
	vim.api.nvim_set_current_buf(M.input_buf)
end

function M.get_input_data()
	if not M.input_buf then
		return nil
	end

	local lines = buffer.return_all_lines_buf(M.input_buf)
	return table.concat(lines, "\n")
end

function M.print_ai_response(content)
	if not M.chat_buf then
		return nil
	end

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
				"[" .. timestamp .. "] Deepseek: ",
			}, content_lines),
			{
				" ",
				"──────────────────────────────────────────────",
			}
		)
	)

	M.scroll_down_win(chat_win, M.chat_buf)
end

function M.print_user_request(prompt)
	if not M.chat_buf then
		return nil
	end

	-- 添加时间戳
	local timestamp = os.date("%H:%M")
	local prompt_lines = type(prompt) == "string" and vim.split(prompt, "\n", { plain = true }) or prompt

	-- 添加用户消息到聊天窗口
	vim.api.nvim_buf_set_lines(
		M.chat_buf,
		-1,
		-1,
		false,
		vim.list_extend(
			vim.list_extend({
				" ",
				"[" .. timestamp .. "] You: ",
			}, prompt_lines),
			{
				" ",
				"──────────────────────────────────────────────",
			}
		)
	)

	M.scroll_down_win(chat_win, M.chat_buf)
end

function M.clear_input_buf()
	if M.input_buf then
		vim.api.nvim_buf_set_lines(M.input_buf, 0, -1, false, { "" })
	end
end

function M.focus_input_win()
	if not M.chat_buf then
		return nil
	end

	vim.api.nvim_win_set_cursor(chat_win, { vim.api.nvim_buf_line_count(M.chat_buf), 0 })
end

function M.scroll_down_win(win_id, buf_id)
	if not win_id then
		return nil
	end
	if not buf_id then
		buf_id = vim.api.nvim_win_get_buf(win_id)
	end
	vim.api.nvim_win_set_cursor(win_id, { vim.api.nvim_buf_line_count(buf_id), 0 })
end

return M
