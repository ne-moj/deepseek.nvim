local M = {}

M.default_config = {
  api_key = nil,  -- Required
  api_url = "https://api.deepseek.com/v1",
  keymaps = {
    generate = "<leader>dg",
    optimize = "<leader>do",
    analyze = "<leader>da",
    chat = "<leader>dc"  -- 新增对话快捷键
  },
  max_tokens = 2048,
  temperature = 0.7,
  enable_ui = true,
  chat = {
    system_prompt = "You are a helpful AI assistant",
    max_history = 10,
    enable_memory = true,
    ui = {
      enable = true,
      position = "float",  -- or "right"
      width = 0.5,  -- float window width ratio
      height = 0.5, -- float window height ratio
      border = "rounded"  -- window border style
    }
  }
}

function M.setup(user_config)
  M.config = vim.tbl_deep_extend("force", M.default_config, user_config or {})
end

function M.get_config()
  return M.config
end

return M
