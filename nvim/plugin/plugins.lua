if vim.g.did_load_plugins_plugin then
  return
end
vim.g.did_load_plugins_plugin = true

-- many plugins annoyingly require a call to a 'setup' function to be loaded,
-- even with default configs

require('nvim-surround').setup()
-- Configure snacks.nvim
require("snacks").setup({
  lazygit = {
    enabled = true,
    float = {
      width = 0.9,
      height = 0.9,
      border = "rounded",
    },
  },
})

local lazygit_toggle = function()
  local Terminal = require("toggleterm.terminal").Terminal
  local lazygit = Terminal:new {
    cmd = "lazygit",
    hidden = true,
    direction = "float",
    float_opts = {
      border = "none",
      width = 100000,
      height = 100000,
      zindex = 200,
    },
    on_open = function(_)
      vim.cmd "startinsert!"
    end,
    on_close = function(_) end,
    count = 99,
  }
  lazygit:toggle()
end

-- Set up keybinding for lazygit
vim.keymap.set('n', '<leader>gg', lazygit_toggle, { desc = 'Open LazyGit' })

-- Example config for init.lua
require("nvim-tree").setup()

-- Optional keymap to toggle it
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>")

