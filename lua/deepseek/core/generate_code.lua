local cfg = require("deepseek.config").get_config()
local class = require("deepseek.class")
local BaseCommand = require("deepseek.core.base_command")
local ui = require("deepseek.ui.window")
local buf = require("deepseek.ui.buffer")
local api = require("deepseek.api")

local GenerateCode = class(BaseCommand)
GenerateCode.temperature = 0.0
GenerateCode.endpoint = "/beta/completions"

function GenerateCode:setup(config)
	BaseCommand.setup(self, config)

	self:create_user_command()
	self:keymaps()
end

function GenerateCode:build_params(input, uuid)
	return {
		model = self.model,
		prompt = "[USER]: " .. input .. ("\n[ASSISTANT]: ```%s\n"):format(vim.bo.filetype),
		stop = { "```" },
	}
end

function GenerateCode:request(uuid, params)
	api.request(params, function(response)
		self:hide_loader(uuid)
		self:get_response(response, uuid)
	end, self.endpoint)
end

function GenerateCode:before_send(input, uuid) end

function GenerateCode:create_user_command()
	vim.api.nvim_create_user_command("DeepseekGenerateCode", function(opts)
		local prompt = table.concat(opts.fargs, " ")

		local vis = buf.get_pos_normal()

		local uuid = self.simple_guid()
		self.uuid_requests[uuid] = { vis = vis }
		self:run(prompt, uuid)
	end, { range = true, nargs = "*" })
end

function BaseCommand:get_response(response, uuid)
	if response and response.choices and response.choices[1] and response.choices[1].text then
		-- Печатаем ответ от AI
		self:print_ai_response(response.choices[1].text, uuid)
	end
end

function GenerateCode:print_ai_response(response, uuid)
	local vis = self.uuid_requests[uuid].vis
	local lines = vim.split(response, "\n")

	-- BaseCommand.print_ai_response(self, response, uuid)

	buf.print_content_before_current_line(lines, vis)
end

function GenerateCode:keymaps()
	vim.keymap.set(
		{ "n", "i" },
		cfg.keymaps.generate_code or "<leader>ag",
		":DeepseekGenerateCode ",
		{ noremap = true }
	)
end

return GenerateCode
