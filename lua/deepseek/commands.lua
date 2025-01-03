local M = {}
local config = require("deepseek.config")
local api = require("deepseek")

function M.setup()
  local cfg = config.get_config()

  -- Generate command
  vim.api.nvim_create_user_command("DeepseekGenerate", function(opts)
    local prompt = table.concat(opts.fargs, " ")
    local response = api.generate_code(prompt)
    if response and response.choices and response.choices[1] then
      vim.api.nvim_put({response.choices[1].text}, "c", true, true)
    end
  end, {nargs = "*"})

  -- Optimize command
  vim.api.nvim_create_user_command("DeepseekOptimize", function()
    local code = vim.fn.getreg("v")
    local response = api.optimize_code(code)
    if response and response.choices and response.choices[1] then
      vim.api.nvim_put({response.choices[1].text}, "c", true, true)
    end
  end, {})

  -- Analyze command
  vim.api.nvim_create_user_command("DeepseekAnalyze", function()
    local code = vim.fn.getreg("v")
    local response = api.analyze_code(code)
    if response and response.choices and response.choices[1] then
      vim.api.nvim_put({response.choices[1].text}, "c", true, true)
    end
  end, {})

  -- Set up keymaps
  if cfg.keymaps then
    vim.keymap.set("n", cfg.keymaps.generate, ":DeepseekGenerate ", {noremap = true})
    vim.keymap.set("v", cfg.keymaps.optimize, ":DeepseekOptimize<CR>", {noremap = true})
    vim.keymap.set("v", cfg.keymaps.analyze, ":DeepseekAnalyze<CR>", {noremap = true})
    vim.keymap.set("n", cfg.keymaps.chat, ":DeepseekChat ", {noremap = true})
  end
end

  -- 添加对话命令
  vim.api.nvim_create_user_command("DeepseekChat", function(opts)
    local cfg = config.get_config()
    local prompt = table.concat(opts.fargs, " ")
    local response = api.chat(prompt)
    
    if response and response.choices and response.choices[1] then
      local content = response.choices[1].message.content
      
      if cfg.chat.ui.enable then
        -- 创建悬浮窗口
        local width = math.floor(vim.o.columns * cfg.chat.ui.width)
        local height = math.floor(vim.o.lines * cfg.chat.ui.height)
        
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))
        
        local win = vim.api.nvim_open_win(buf, true, {
          relative = "editor",
          width = width,
          height = height,
          col = (vim.o.columns - width) / 2,
          row = (vim.o.lines - height) / 2,
          style = "minimal",
          border = cfg.chat.ui.border
        })
        
        -- 设置窗口选项
        vim.api.nvim_win_set_option(win, "wrap", true)
        vim.api.nvim_win_set_option(win, "number", false)
        vim.api.nvim_win_set_option(win, "relativenumber", false)
      else
        -- 回退到插入模式
        vim.api.nvim_put({content}, "c", true, true)
      end
    end
  end, {nargs = "*"})

return M
