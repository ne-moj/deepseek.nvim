local M = {}
local config = require("deepseek.config")
local api = require("deepseek.api")

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

  -- Chat command
  vim.api.nvim_create_user_command("DeepseekChat", function(opts)
    local cfg = config.get_config()
    
    -- 创建主聊天窗口
    local chat_width = math.floor(vim.o.columns * cfg.chat.ui.width)
    local chat_height = math.floor(vim.o.lines * cfg.chat.ui.height * 0.8)
    
    local chat_buf = vim.api.nvim_create_buf(false, true)
    local chat_win = vim.api.nvim_open_win(chat_buf, true, {
      relative = "editor",
      width = chat_width,
      height = chat_height,
      col = (vim.o.columns - chat_width) / 2,
      row = (vim.o.lines - chat_height) / 2 - 10,
      style = "minimal",
      border = {
        {"🭽", "FloatBorder"},
        {"▔", "FloatBorder"},
        {"🭾", "FloatBorder"},
        {"▕", "FloatBorder"},
        {"🭿", "FloatBorder"},
        {"▁", "FloatBorder"},
        {"🭼", "FloatBorder"},
        {"▏", "FloatBorder"}
      },
      title = {
        {text = " Deepseek Chat ", pos = "N"},
        {text = "", hl = "FloatBorder", pos = "NE"}
      },
      title_pos = "center"
    })
    
    -- 设置高亮组
    vim.api.nvim_set_hl(0, "DeepseekUser", {fg = "#569CD6", bold = true})
    vim.api.nvim_set_hl(0, "DeepseekAI", {fg = "#4EC9B0", bold = true})
    vim.api.nvim_set_hl(0, "DeepseekTimestamp", {fg = "#6B737F", italic = true})
    
    -- 创建输入窗口
    local input_width = chat_width
    local input_height = 3
    local input_buf = vim.api.nvim_create_buf(false, true)
    local input_win = vim.api.nvim_open_win(input_buf, true, {
      relative = "editor",
      width = input_width,
      height = input_height,
      col = (vim.o.columns - input_width) / 2,
      row = (vim.o.lines - input_height) / 2 + chat_height / 2 - 5,
      style = "minimal",
      border = cfg.chat.ui.border
    })
    
    -- 设置窗口选项
    vim.api.nvim_win_set_option(chat_win, "wrap", true)
    vim.api.nvim_win_set_option(chat_win, "number", false)
    vim.api.nvim_win_set_option(chat_win, "relativenumber", false)
    
    -- 输入窗口映射
    vim.api.nvim_buf_set_keymap(input_buf, "n", "<CR>", [[<Cmd>lua require("deepseek.commands").send_chat()<CR>]], {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(input_buf, "i", "<CR>", [[<Cmd>lua require("deepseek.commands").send_chat()<CR>]], {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(input_buf, "n", "<Esc>", [[<Cmd>lua require("deepseek.commands").close_chat()<CR>]], {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(input_buf, "i", "<Esc>", [[<Cmd>lua require("deepseek.commands").close_chat()<CR>]], {noremap = true, silent = true})
    
    -- 保存窗口引用
    M.chat_win = chat_win
    M.chat_buf = chat_buf
    M.input_win = input_win
    M.input_buf = input_buf
    
    -- 设置初始提示
    vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, {
      " ",
      "┌──────────────────────────────────────────────┐",
      "│  Welcome to Deepseek Chat!                   │",
      "│  Type your message below and press Enter     │",
      "│  to send. Press Esc to close the window.     │",
      "└──────────────────────────────────────────────┘",
      " "
    })
  end, {nargs = "*"})

function M.send_chat()
  local cfg = config.get_config()
  local lines = vim.api.nvim_buf_get_lines(M.input_buf, 0, -1, false)
  local prompt = table.concat(lines, "\n")
  
  -- 清空输入框
  vim.api.nvim_buf_set_lines(M.input_buf, 0, -1, false, {""})
  
  -- 添加时间戳
  local timestamp = os.date("%H:%M")
  
  -- 添加用户消息到聊天窗口
  vim.api.nvim_buf_set_lines(M.chat_buf, -1, -1, false, {
    " ",
    " " .. timestamp,
    " You",
    " ",
    prompt,
    " ",
    "──────────────────────────────────────────────"
  })
  
  -- 获取响应
  local response = api.chat(prompt, cfg)
  if response and response.choices and response.choices[1] then
    local content = response.choices[1].message.content
    local timestamp = os.date("%H:%M")
    
    vim.api.nvim_buf_set_lines(M.chat_buf, -1, -1, false, {
      " ",
      " " .. timestamp,
      " Deepseek",
      " ",
      content,
      " ",
      "──────────────────────────────────────────────"
    })
  end
  
  -- 滚动到底部
  vim.api.nvim_win_set_cursor(M.chat_win, {vim.api.nvim_buf_line_count(M.chat_buf), 0})
end

  -- Set up keymaps
  if cfg.keymaps then
    vim.keymap.set("n", cfg.keymaps.generate, ":DeepseekGenerate ", {noremap = true})
    vim.keymap.set("v", cfg.keymaps.optimize, ":DeepseekOptimize<CR>", {noremap = true})
    vim.keymap.set("v", cfg.keymaps.analyze, ":DeepseekAnalyze<CR>", {noremap = true})
    vim.keymap.set("n", cfg.keymaps.chat, ":DeepseekChat ", {noremap = true})
  end
end

return M
