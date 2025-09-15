
if vim.g.did_load_statuscol_plugin then
  return
end
vim.g.did_load_statuscol_plugin = true

local builtin = require('statuscol.builtin')
require('statuscol').setup {
  setopt = true,
  relculright = true,
  segments = {
    { text = { '%s' }, click = 'v:lua.ScSa' },             -- signs
    {
      text = { builtin.foldfunc },                          -- <-- add this
      condition = { builtin.has_fold },                     -- only show if fold exists
      click = 'v:lua.ScFa',                                 -- you can define a fold toggle function
    },
    {
      text = { builtin.lnumfunc, ' ' },                     -- line numbers
      condition = { true, builtin.not_empty },
      click = 'v:lua.ScLa',
    },
  },
}

