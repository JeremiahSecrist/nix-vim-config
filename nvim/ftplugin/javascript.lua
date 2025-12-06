-- 1. Define the tsserver config
vim.lsp.config("tsserver", {
  cmd = {"typescript-language-server", "--stdio"},
  filetypes = {"javascript", "javascriptreact", "typescript", "typescriptreact"},
  root_dir = vim.fs.dirname(vim.fs.find({'package.json', '.git'}, { upward = true })[1] or vim.loop.cwd()),
  auto_archive = false, -- Disable autoArchive prompt
})

-- 2. Enable it
vim.lsp.enable({"tsserver"})
