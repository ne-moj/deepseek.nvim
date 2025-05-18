local cfg = require("deepseek.config").get_config()
local class = require("deepseek.class")
local BaseCommand = require("deepseek.core.base_command")
local ui = require("deepseek.ui.window")

local Translate = class(BaseCommand)

function Translate:run()
	-- TODO: Get data from buffer
	-- BaseCommand.run(self)
end

function Chat:close()
	ui.close_chat()
end

function Chat:setup(config)
	BaseCommand.setup(self, config)

	self:create_user_command()
	self:keymaps()
end

function Chat:create_user_command()
	vim.api.nvim_create_user_command("DeepseekChat", function(opts)
		if opts.args then
			ui.set_position(opts.args)
		end
		ui.toggle_popup()
	end, {
		nargs = "?",
		complete = function()
			return { "left", "right", "top", "bottom", "float" }
		end,
	})
end

function Chat:keymaps()
	vim.keymap.set("n", cfg.keymaps.chat.default or "<leader>acc", ":DeepseekChat<CR>", { noremap = true })
	if cfg.keymaps.chat.popup then
		vim.keymap.set("n", cfg.keymaps.chat.popup, ":DeepseekChat float<CR>", { noremap = true })
	end
	if cfg.keymaps.chat.left then
		vim.keymap.set("n", cfg.keymaps.chat.left, ":DeepseekChat left<CR>", { noremap = true })
	end
	if cfg.keymaps.chat.right then
		vim.keymap.set("n", cfg.keymaps.chat.right, ":DeepseekChat right<CR>", { noremap = true })
	end
	if cfg.keymaps.chat.top then
		vim.keymap.set("n", cfg.keymaps.chat.top, ":DeepseekChat top<CR>", { noremap = true })
	end
	if cfg.keymaps.chat.bottom then
		vim.keymap.set("n", cfg.keymaps.chat.bottom, ":DeepseekChat bottom<CR>", { noremap = true })
	end
	vim.keymap.set(
		{ "n" },
		cfg.keymaps.n_send_chat or "<CR>",
		[[<Cmd>lua require("deepseek.core.chat"):run()<CR>]],
		{ buffer = ui.input_buf, noremap = true, silent = true }
	)

	vim.keymap.set(
		{ "i" },
		cfg.keymaps.i_send_chat or "<C-i>",
		[[<Cmd>lua require("deepseek.core.chat"):run()<CR>]],
		{ buffer = ui.input_buf, noremap = true, silent = true }
	)

	vim.keymap.set(
		{ "n" },
		cfg.keymaps.n_close_chat or "q",
		[[<Cmd>lua require("deepseek.core.chat"):close()<CR>]],
		{ buffer = ui.chat_buf, noremap = true, silent = true }
	)

	vim.keymap.set(
		{ "n" },
		cfg.keymaps.n_close_chat or "q",
		[[<Cmd>lua require("deepseek.ui.window").close_chat()<CR>]],
		{ buffer = ui.input_buf, noremap = true, silent = true }
	)

	vim.keymap.set(
		{ "i" },
		cfg.keymaps.i_close_chat or "<C-q>",
		[[<Cmd>lua require("deepseek.ui.window").close_chat()<CR>]],
		{ buffer = ui.chat_buf, noremap = true, silent = true }
	)

	vim.keymap.set(
		{ "i" },
		cfg.keymaps.i_close_chat or "<C-q>",
		[[<Cmd>lua require("deepseek.ui.window").close_chat()<CR>]],
		{ buffer = ui.input_buf, noremap = true, silent = true }
	)
end

return Chat
