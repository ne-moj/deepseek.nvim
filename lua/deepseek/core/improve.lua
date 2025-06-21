local cfg = require("deepseek.config").get_config()
local class = require("deepseek.class")
local BaseCommand = require("deepseek.core.base_command")
local buf = require("deepseek.ui.buffer")

local Improve = class(BaseCommand)

function Improve:setup(config)
	BaseCommand.setup(self, config)

	self:create_user_command()
	self:keymaps()
end

function Improve:build_system_prompt(uuid)
	-- Формируем системный промт
	table.insert(self.messages, { role = "system", content = self.cfg.system_prompt })
end

function Improve:create_user_command()
	vim.api.nvim_create_user_command("DeepseekImprove", function(opts)
		local prompt = table.concat(opts.fargs, " ")

		local vis = buf.get_pos_visual_selection()
		local selection = buf.get_visual_selection(vis)
		local text = table.concat(selection, "\n")

		local uuid = self.simple_guid()
		self.uuid_requests[uuid] = { vis = vis }
		self:run(prompt .. ": " .. text, uuid)
	end, { range = true, nargs = "*" })
end

function Improve:print_ai_response(response, uuid)
	local vis = self.uuid_requests[uuid].vis
	local lines = vim.split(response, "\n")

	-- BaseCommand.print_ai_response(self, response, uuid)

	buf.print_content_to_visual_selection(lines, vis)
end

function Improve:keymaps()
	vim.keymap.set("v", cfg.keymaps.improve or "<leader>ai", ":DeepseekImprove ", { noremap = true })
end

return Improve
