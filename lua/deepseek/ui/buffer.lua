local M = {}

function M.return_all_lines_buf(buf)
	return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

return M
