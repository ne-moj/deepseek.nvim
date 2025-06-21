--- Simple logging module for Neovim plugins
-- @module LOG
-- @author: @Kurama622
--
-- Reference: https://github.com/Kurama622/llm.nvim/blob/main/lua/llm/common/log.lua
-- Updated by @ne-moj and Deepseek
local LOG = {}

--- Setup logger configuration
-- @param cfg Configuration table
-- @field cfg.enable_trace boolean Enable trace logging
-- @field cfg.log_level number Log level (0=DEBUG, 1=INFO, 2=WARN, 3=ERROR)
-- @field cfg.plugin_name string Plugin name for notifications
function LOG.setup(cfg)
	LOG.enable_trace = cfg.enable_trace
	LOG.log_level = cfg.log_level or 1 -- Default to INFO
	LOG.plugin_name = cfg.plugin_name or "Plugin"
end

local function format_string(...)
	local info = debug.getinfo(3, "n")
	local fn = info and info.name or "anonymous"
	local args = { ... }

	for i = 1, select("#", ...) do
		local v = args[i]
		args[i] = type(v) == "table" and vim.inspect(v)
			or type(v) == "function" and "<" .. tostring(v) .. ">"
			or tostring(v)
	end

	return string.format("[%s] %s", fn, table.concat(args, " "))
end

--- Log debug message
function LOG:DEBUG(...)
	if self.log_level <= 0 then
		vim.notify(format_string(...), vim.log.levels.DEBUG, { title = self.plugin_name })
	end
end

--- Log info message
function LOG:INFO(...)
	if self.log_level <= 1 then
		vim.notify(format_string(...), vim.log.levels.INFO, { title = self.plugin_name })
	end
end

--- Log warning message
function LOG:WARN(...)
	if self.log_level <= 2 then
		vim.notify(format_string(...), vim.log.levels.WARN, { title = self.plugin_name })
	end
end

--- Log error message
function LOG:ERROR(...)
	if self.log_level <= 3 then
		vim.notify(format_string(...), vim.log.levels.ERROR, { title = self.plugin_name })
	end
end

--- Log trace message (if enabled)
function LOG:TRACE(...)
	if self.enable_trace then
		vim.notify(format_string(...), vim.log.levels.TRACE, { title = self.plugin_name })
	end
end

return LOG
