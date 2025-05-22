local M = {}
local timer = nil
local frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local frame_index = 1
local loader_prefix = ""
local loader_postfix = ""

function M.show()
	if timer then
		return
	end
	timer = vim.loop.new_timer()
	timer:start(
		0,
		100,
		vim.schedule_wrap(function()
			vim.cmd(
				"echohl ModeMsg | echon '"
					.. loader_prefix
					.. frames[frame_index]
					.. loader_postfix
					.. "' | echohl None"
			)
			frame_index = (frame_index % #frames) + 1
		end)
	)
end

function M.hide()
	if timer then
		timer:stop()
		timer:close()
		timer = nil
		vim.cmd("echohl ModeMsg | echon '" .. load_success .. "' | echohl None")
	end
end

function M.setup(opts)
	loader_prefix = opts.loader_prefix or ""
	loader_postfix = opts.loader_postfix or ""
	load_success = opts.load_success or ""
end

return M
