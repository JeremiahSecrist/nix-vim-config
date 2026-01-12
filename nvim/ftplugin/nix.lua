-- Exit if the language server isn't available
if vim.fn.executable('nil') ~= 1 then
  return
end

local root_files = {
  'flake.nix',
  'default.nix',
  'shell.nix',
  '.git',
}

local root = vim.fs.find(root_files, { upward = true })[1]
if root then
  root = vim.fs.dirname(root)
end

vim.lsp.start({
  name = 'nil_ls',
  cmd = { 'nil' },
  root_dir = root or vim.loop.cwd(), -- ← important fallback
  capabilities = require('user.lsp').make_client_capabilities(),
  settings = {
    ["nil"] = {
      autoArchive = true,
    },
  },
})

