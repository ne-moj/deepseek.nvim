local cfg = require("deepseek.config").get_config()
local class = require("deepseek.class")
local BaseCommand = require("deepseek.core.base_command")
local buf = require("deepseek.ui.buffer")
local api = require("deepseek.api")

local OptimizeCode = class(BaseCommand)
OptimizeCode.temperature = 0.0
OptimizeCode.endpoint = "/beta/completions"

function OptimizeCode:setup(config)
	BaseCommand.setup(self, config)

	self:create_user_command()
	self:keymaps()
end

function OptimizeCode:build_params(input, uuid)
	local prompt = ""
	if self.cfg and self.cfg.system_prompt then
		prompt = "[SYSTEM]: " .. (self.cfg.system_prompt):format(vim.bo.filetype) .. "\n"
	end

	prompt = prompt .. "[USER]: " .. input .. ("\n[ASSISTANT]: ```%s\n"):format(vim.bo.filetype)
	return {
		model = self.model,
		prompt = prompt,
		max_tokens = self.max_tokens,
		temperature = self.temperature,
		stop = { "```" },
	}
end

function OptimizeCode:request(uuid, params)
	api.request(params, function(response)
		self:hide_loader(uuid)
		self:get_response(response, uuid)
	end, self.endpoint)
end

function OptimizeCode:create_user_command()
	vim.api.nvim_create_user_command("DeepseekOptimizeCode", function()
		local vis = buf.get_pos_visual_selection()
		local selection = buf.get_visual_selection(vis)
		local text = table.concat(selection, "\n")

		local uuid = self.simple_guid()

		self.uuid_requests[uuid] = { vis = vis }
		self:run(text, uuid)
	end, { range = true })
end

function OptimizeCode:get_response(response, uuid)
	if response and response.choices and response.choices[1] and response.choices[1].text then
		-- Печатаем ответ от AI
		self:print_ai_response(response.choices[1].text, uuid)
	end
end

function OptimizeCode:print_ai_response(response, uuid)
	local vis = self.uuid_requests[uuid].vis
	local lines = vim.split(response, "\n")

	-- BaseCommand.print_ai_response(self, response, uuid)

	buf.print_content_to_visual_selection(lines, vis)
end

function OptimizeCode:keymaps()
	vim.keymap.set("v", cfg.keymaps.optimize_code or "<leader>ao", ":DeepseekOptimizeCode<CR>", { noremap = true })
end

return OptimizeCode
