local cfg = require("deepseek.config").get_config()
local class = require("deepseek.class")
local BaseCommand = require("deepseek.core.base_command")
local buf = require("deepseek.ui.buffer")
local api = require("deepseek.api")

local AnalyzeCode = class(BaseCommand)
AnalyzeCode.temperature = 0.0
AnalyzeCode.endpoint = "/beta/completions"

function AnalyzeCode:setup(config)
	BaseCommand.setup(self, config)

	self:create_user_command()
	self:keymaps()
end

function AnalyzeCode:build_params(input, uuid)
	local user_text = input.text
	local prompt = ""
	if self.cfg and self.cfg.system_prompt then
		prompt = "[SYSTEM]: " .. (self.cfg.system_prompt):format(vim.bo.filetype) .. "\n"
	end

	if self.cfg and self.cfg.user_prompt then
		user_text = (self.cfg.system_prompt):format(input.prompt, vim.bo.filetype, input.text)
	end

	prompt = prompt .. "[USER]: " .. user_text .. ("\n[ASSISTANT]: ```%s\n"):format(vim.bo.filetype)
	return {
		model = self.model,
		prompt = prompt,
		max_tokens = self.max_tokens,
		temperature = self.temperature,
		stop = { "```" },
	}
end

function AnalyzeCode:request(uuid, params)
	api.request(params, function(response)
		self:hide_loader(uuid)
		self:get_response(response, uuid)
	end, self.endpoint)
end

function AnalyzeCode:create_user_command()
	vim.api.nvim_create_user_command("DeepseekAnalyzeCode", function(opts)
		local prompt = table.concat(opts.fargs, " ")
		local vis = buf.get_pos_visual_selection()
		local selection = buf.get_visual_selection(vis)
		local text = table.concat(selection, "\n")

		local uuid = self.simple_guid()
		self.uuid_requests[uuid] = { vis = vis }

		self:run({ prompt = prompt, text = text }, uuid)
	end, { range = true, nargs = "*" })
end

function AnalyzeCode:get_response(response, uuid)
	if response and response.choices and response.choices[1] and response.choices[1].text then
		-- Printing the response from AI
		self:print_ai_response(response.choices[1].text, uuid)
	end
end

function AnalyzeCode:print_ai_response(response, uuid)
	local vis = self.uuid_requests[uuid].vis
	local lines = vim.split(response, "\n")

	-- BaseCommand.print_ai_response(self, response, uuid)

	buf.print_content_to_visual_selection(lines, vis)
end

function AnalyzeCode:keymaps()
	vim.keymap.set("v", cfg.keymaps.analyse_code or "<leader>az", ":DeepseekAnalyzeCode ", { noremap = true })
end

return AnalyzeCode
