local cfg = require("deepseek.config").get_config()
local class = require("deepseek.class")
local BaseCommand = require("deepseek.core.base_command")
local buf = require("deepseek.ui.buffer")

local Translate = class(BaseCommand)

Translate.language = "English"
Translate.second_language = "Russian"

function Translate:setup(config)
	BaseCommand.setup(self, config)

	if config then
		self.language = config.language or self.language
		self.second_language = config.second_language or self.second_language
	end

	self:create_user_command()
	self:keymaps()
end

function Translate:build_system_prompt(uuid)
	-- Формируем системный промт
	table.insert(
		self.messages,
		{ role = "system", content = (self.cfg.system_prompt):format(self.cfg.language, self.cfg.second_language) }
	)
end

function Translate:create_user_command()
	vim.api.nvim_create_user_command("DeepseekTranslate", function()
		local vis = buf.get_pos_visual_selection()
		local selection = buf.get_visual_selection(vis)
		local text = table.concat(selection, "\n")

		local uuid = self.simple_guid()
		self.uuid_requests[uuid] = { vis = vis }
		self:run(text, uuid)
	end, { range = true })
end

function Translate:print_ai_response(response, uuid)
	local vis = self.uuid_requests[uuid].vis
	local lines = vim.split(response, "\n")

	-- BaseCommand.print_ai_response(self, response, uuid)

	buf.print_content_to_visual_selection(lines, vis)

	-- чистим, чтобы не хранить лишнее
	self.uuid_requests[uuid] = nil
end

function Translate:keymaps()
	vim.keymap.set("v", cfg.keymaps.translate or "<leader>at", ":DeepseekTranslate<CR>", { noremap = true })
end

return Translate
