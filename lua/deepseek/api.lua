local M = {}

local api_key = nil
local api_url = "https://api.deepseek.com/v1"

function M.setup(cfg)
  api_key = cfg.api_key
  if cfg.api_url then
    api_url = cfg.api_url
  end
end

local function make_request(endpoint, params)
  local headers = {
    ["Content-Type"] = "application/json",
    ["Authorization"] = "Bearer " .. api_key
  }

  local body = vim.fn.json_encode(params)
  local response = vim.fn.system({
    "curl", "-s", "-X", "POST",
    "-H", "Content-Type: application/json",
    "-H", "Authorization: Bearer " .. api_key,
    "-d", body,
    api_url .. endpoint
  })

  return vim.fn.json_decode(response)
end

function M.generate_code(prompt)
  local params = {
    model = "deepseek-coder",
    prompt = prompt,
    max_tokens = 2048,
    temperature = 0.7
  }
  return make_request("/completions", params)
end

function M.optimize_code(code)
  local params = {
    model = "deepseek-coder",
    prompt = "Optimize this code:\n" .. code,
    max_tokens = 2048,
    temperature = 0.5
  }
  return make_request("/completions", params)
end

function M.analyze_code(code)
  local params = {
    model = "deepseek-coder",
    prompt = "Analyze this code:\n" .. code,
    max_tokens = 1024,
    temperature = 0.3
  }
  return make_request("/completions", params)
end

-- 对话功能实现
local chat_history = {}

function M.chat(message, cfg)
  -- 构建对话上下文
  local messages = {}
  if cfg.chat.enable_memory and #chat_history > 0 then
    table.insert(messages, {role = "system", content = cfg.chat.system_prompt})
    for _, msg in ipairs(chat_history) do
      table.insert(messages, msg)
    end
  end
  table.insert(messages, {role = "user", content = message})

  -- 发送请求
  local params = {
    model = "deepseek-chat",
    messages = messages,
    max_tokens = cfg.max_tokens,
    temperature = cfg.temperature
  }
  local response = make_request("/chat/completions", params)

  -- 更新对话历史
  if cfg.chat.enable_memory then
    table.insert(chat_history, {role = "user", content = message})
    if response and response.choices and response.choices[1] then
      table.insert(chat_history, {
        role = "assistant",
        content = response.choices[1].message.content
      })
    end
    -- 保持历史记录不超过最大限制
    while #chat_history > cfg.chat.max_history do
      table.remove(chat_history, 1)
    end
  end

  return response
end

return M
