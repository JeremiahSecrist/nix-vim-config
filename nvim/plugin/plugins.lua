if vim.g.did_load_plugins_plugin then
  return
end
vim.g.did_load_plugins_plugin = true
local telescope = require('telescope')

-- many plugins annoyingly require a call to a 'setup' function to be loaded,
-- even with default configs

require("kanagawa").load("wave")
require('nvim-surround').setup()
require('oil').setup()
require('flash').setup()
telescope.setup {
  -- opts...
}
telescope.load_extension('manix')
require("toggleterm").setup({
  open_mapping = [[<C-\>]],   -- Ctrl-\ toggles terminal globally
  direction = "float",
  start_in_insert = true,     -- terminal opens in insert mode
  shade_terminals = true,
  float_opts = {
    border = "curved",
    width = 100,
    height = 30,
  },
})
require('nvim-autopairs').setup()
require('mini.ai').setup()
require("bufferline").setup()
require('typst-preview').setup()
require("tiny-inline-diagnostic").setup({
  -- ...
  signs = {
    left = "",
    right = "",
    diag = "●",
    arrow = "    ",
    up_arrow = "    ",
    vertical = " │",
    vertical_end = " └",
  },
  blend = {
    factor = 0.22,
  },
  -- ...
})
require('Comment').setup()
require('harpoon').setup()
require("lspconfig").gleam.setup({})
require("actions-preview").setup()
