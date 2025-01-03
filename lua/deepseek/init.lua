local M = {}

local config = require("deepseek.config")
local commands = require("deepseek.commands")
local api = require("deepseek.api")

function M.setup(user_opts)
  config.setup(user_opts)
  local cfg = config.get_config()
  
  -- 初始化API模块
  api.setup(cfg)
  
  -- 设置命令
  commands.setup()
end

-- 导出API功能
M.generate_code = api.generate_code
M.optimize_code = api.optimize_code
M.analyze_code = api.analyze_code
M.chat = api.chat

return M
