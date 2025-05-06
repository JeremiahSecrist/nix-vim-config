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

-- Set up keybinding for lazygit
vim.keymap.set('n', '<leader>gg', function() Snacks.lazygit.open() end, { desc = 'Open LazyGit' }) 

