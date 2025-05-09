# Deepseek.nvim

A powerful AI assistant plugin for Neovim, providing code generation, optimization, analysis, and conversational AI capabilities directly in your editor.

## Features

- Code generation from natural language prompts
- Code optimization suggestions
- Code analysis and explanation
- AI chat with conversation history
- Customizable keybindings
- Configurable API settings
- Floating window UI for chat interface

## Installation

Using packer.nvim:

```lua
use {
  "ne-moj/deepseek.nvim",
  dependencies = {
    "numToStr/Comment.nvim",
  },
  config = function()
    require("deepseek").setup({
      api_key = "your-api-key-here", -- Optional configuration
      api_url = "https://api.deepseek.com/v1",
      keymaps = {
        generate = "<leader>dg",
        optimize = "<leader>do",
        analyze = "<leader>da",
        chat = "<leader>dc",
      },
      chat = {
        system_prompt = "You are a helpful %s-assistant",
        max_history = 10,
        enable_memory = true,
        ui = {
          enable = true,
          position = "float",
          width = 0.5,
          height = 0.5,
          border = "rounded",
        },
      },
    })
  end,
}
```

## Usage

### Commands

- `:DeepseekGenerate <prompt>` - Generate code from natural language prompt
- `:DeepseekOptimize` - Optimize selected code (visual mode)
- `:DeepseekAnalyze` - Analyze selected code (visual mode)
- `:DeepseekChat <message>` - Start a chat with the AI

### Keybindings (default)

- `<leader>dg` - Start code generation prompt
- `<leader>do` - Optimize selected code
- `<leader>da` - Analyze selected code
- `<leader>dc` - Start AI chat

## Configuration

```lua
require('deepseek').setup({
  api_key = "your-api-key",  -- Required
  api_url = "https://api.deepseek.com/v1",  -- Optional
  keymaps = {
    generate = "<leader>dg",  -- Code generation
    optimize = "<leader>do",  -- Code optimization
    analyze = "<leader>da",   -- Code analysis
    chat = "<leader>dc"      -- AI chat
  },
  max_tokens = 2048,  -- Max tokens per request
  temperature = 0.7,  -- Creativity level
  enable_ui = true,   -- Enable/disable UI elements
  chat = {
    system_prompt = "You are a helpful AI assistant",  -- System prompt for chat
    model = "deepseek-chat", -- deepseek-chat | deepseek-reasoner
    max_history = 10,  -- Maximum conversation history length
    enable_memory = true,  -- Enable conversation memory
    ui = {
      enable = true,
      position = "float",  -- or "right"
      width = 0.5,  -- float window width ratio
      height = 0.5, -- float window height ratio
      border = "rounded"  -- window border style
    }
  },
  generate_code = {
    model = "deepseek-chat",
    system_prompt = "You are a senior %s developer. You have no time for greetings or politeness, but you code brilliantly. Write ONLY code. Be concise. Explain only if asked.",
    max_tokens = 2048,
    temperature = 0.0,
  },
  optimize_code = {
    model = "deepseek-chat",
    system_prompt = "You’re a senior %s developer. No time for greetings or niceties—just flawless code. Reply ONLY with code. Keep it short. Explain only if explicitly asked.",
    max_tokens = 2048,
    temperature = 0.2,
  },
  analyze_code = {
    model = "deepseek-chat",
    system_prompt = "You’re a senior %s developer. Your goal is to teach beginners, so you explain everything in clear detail. Your programming skills are unmatched. Reply ONLY with explanations. Be concise. Break it down when needed.",
    user_promt = "Question: %s; Code: %s",
    max_tokens = 2048,
    temperature = 0.5,
  }
})
```

## Requirements

- Neovim 0.7+
- curl (for API requests)
- Deepseek API key

## GitHub Repository Description

When creating the GitHub repository, use this description:

"Deepseek.nvim - A powerful AI assistant plugin for Neovim, providing code generation, optimization, analysis, and conversational AI capabilities with a modern floating window interface."
