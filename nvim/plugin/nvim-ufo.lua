local ufo = require('ufo')
vim.o.foldcolumn = '1'
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]

vim.keymap.set('n', 'zR',ufo.openAllFolds,{ desc="Open all folds"})
vim.keymap.set('n', 'zM',ufo.closeAllFolds,{ desc="Close all folds"})
vim.keymap.set('n', 'zK',function ()
    local winid = ufo.peekFoldedLinesUnderCursor()
    if not winid then 
      vim.lsp.buf.hover()
    end
end, {desc = "Peek Fold"})

ufo.setup({
  provider_selector = function (bufr,filetype,buftype)
    return {'lsp','indent'}
  end
})
