# Deepseek.nvim

Deepseek.nvim is a Neovim plugin that brings the power of Deepseek AI straight into your editor. It can generate and optimize code, analyze selections, improve or translate text and provides a handy chat interface.

## Features
- Generate code from a prompt
- Optimize and refactor selected code
- Analyze selected fragments in detail
- Translate text between languages
- Interactive chat with history
- Flexible keymaps and interface

## Requirements
- Neovim 0.7+
- `curl` for HTTP requests
- Deepseek API key

## Installation
Example for `packer.nvim`:
```lua
use {
  "ne-moj/deepseek.nvim",
  dependencies = { 
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("deepseek").setup({
      api = { key = "YOUR_API_KEY" }
    })
  end,
}
```

## Usage

### Commands
- `:DeepseekGenerate <prompt>` — generate code in the current buffer
- `:DeepseekOptimize` — optimize the selected code
- `:DeepseekAnalyze [prompt]` — analyze the selected fragment
- `:DeepseekImprove` — improve the selected text
- `:DeepseekTranslate` — translate the selected text
- `:DeepseekChat [position]` — open chat (float, left, right, top, bottom)

Default keymaps are defined (see `lua/deepseek/config.lua`) but can be overridden.

## Minimal configuration
```lua
require("deepseek").setup({
  api = {
    key = "YOUR_API_KEY",
    url = "https://api.deepseek.com",
    default_model = "deepseek-chat",
  },
  keymaps = {
    generate_code = "<leader>ag",
    optimize_code = "<leader>ao",
    analyze_code  = "<leader>az",
    translate     = "<leader>at",
    improve       = "<leader>ai",
    chat = { default = "<leader>acc" },
  },
  ui = {
    window = {
      default_position = "float",
      width = 0.7,
      height = 0.6,
      border = "rounded",
    },
  },
})
```
Detailed options can be found in [`lua/deepseek/config.lua`](lua/deepseek/config.lua).

## License
This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
