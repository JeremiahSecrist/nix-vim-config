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
