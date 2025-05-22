local strings = require("plenary.strings")
local M = {}

function M.return_all_lines_buf(buf)
	return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

-- Функция которая определяет позиции выделеного, а также буфер и метод выделения
function M.get_pos_visual_selection()
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

function M.get_visual_selection(vis)
	if not vis then
		vis = M.get_pos_visual_selection()
	end

	local lines = vim.api.nvim_buf_get_lines(vis.bufnr, vis.start_line, vis.end_line + 1, false)

	if vis.mode == "V" then
		return M.get_visual_lines_selection(lines, vis)
	elseif vis.mode == "v" then
		return M.get_visual_chars_selection(lines, vis)
	elseif vis.mode == "\22" then
		return M.get_visual_block_selection(lines, vis)
	else
		return ""
	end
end

-- mode == 'v'
function M.get_visual_chars_selection(lines, vis)
	-- Обрабатываем последнюю строку (может быть частичной)
	if #lines > 0 then
		local last_line = lines[#lines]
		lines[#lines] = string.sub(last_line, 1, vis.end_col)
		-- нужно добавить один символ к концу
		lines[#lines] = table.concat({
			lines[#lines],
			strings.strcharpart(string.sub(last_line, vis.end_col + 1), 0, 1),
		}, "")

		lines[1] = string.sub(lines[1], vis.start_col + 1)
	end

	return lines
end

-- mode == 'V'
function M.get_visual_lines_selection(lines, vis)
	return lines
end

-- mode == \22 (block)
function M.get_visual_block_selection(lines, vis)
	local block_selection = {}
	for _, line in ipairs(lines) do
		local start_col = math.min(vis.start_col, vis.end_col)
		local end_col = math.max(vis.start_col + 1, vis.end_col + 1)
		-- Ограничиваем колонки по длине строки
		local text = string.sub(line, 1, end_col - 1)

		-- нужно добавить один символ к концу
		text = table.concat({
			text,
			strings.strcharpart(string.sub(line, end_col), 0, 1),
		}, "")

		text = string.sub(text, start_col + 1)

		table.insert(block_selection, text)
	end
	return block_selection
end

function M.print_content_to_visual_selection(lines, vis)
	if not vis then
		vis = M.get_pos_visual_selection()
	end

	-- Проверяем, что строки существуют
	if not vim.api.nvim_buf_is_valid(vis.bufnr) then
		return
	end

	if vis.mode == "v" then
		local line_count = vim.api.nvim_buf_line_count(vis.bufnr)

		if vis.start_line >= line_count then
			vis.start_line = line_count
		end
		if vis.end_line >= line_count then
			vis.end_line = line_count
		end

		-- Получаем строки и их длину в байтах
		local start_line = vim.api.nvim_buf_get_lines(vis.bufnr, vis.start_line, vis.start_line + 1, false)[1] or ""
		local end_line = vim.api.nvim_buf_get_lines(vis.bufnr, vis.end_line, vis.end_line + 1, false)[1] or ""

		local start_col_max = #start_line
		local end_col_max = #end_line

		if vis.start_col > start_col_max then
			vis.start_col = start_col_max
		end
		-- нужно в end_col вставить ещё один символ, а то вставлять будет не туда
		local last_char = strings.strcharpart(string.sub(end_line, vis.end_col + 1), 0, 1)
		vis.end_col = vis.end_col + #last_char
		if vis.end_col > end_col_max then
			vis.end_col = end_col_max
		end

		-- Вызываем безопасную вставку
		vim.api.nvim_buf_set_text(vis.bufnr, vis.start_line, vis.start_col, vis.end_line, vis.end_col, lines)
	elseif vis.mode == "V" then
		vim.api.nvim_buf_set_lines(vis.bufnr, vis.start_line, vis.end_line + 1, false, lines)
	elseif vis.mode == "\22" then
		local start_line = math.min(vis.start_line, vis.end_line)
		local end_line = math.max(vis.start_line, vis.end_line)
		local start_col = math.min(vis.start_col, vis.end_col)
		local end_col = math.max(vis.start_col, vis.end_col)

		for i = start_line, end_line do
			local line = vim.api.nvim_buf_get_lines(vis.bufnr, i, i + 1, false)[1] or ""

			local start_col = math.min(vis.start_col, vis.end_col)
			local end_col = math.max(vis.start_col + 1, vis.end_col + 1)

			local last_char = strings.strcharpart(string.sub(line, end_col), 0, 1)
			end_col = end_col + #last_char

			local before = string.sub(line, 1, start_col)
			local after = string.sub(line, end_col, #line)
			local insert_text = lines[(i - start_line) + 1] or ""
			local new_line = before .. insert_text .. after

			vim.api.nvim_buf_set_lines(vis.bufnr, i, i + 1, false, { new_line })
		end
	end
end

return M
