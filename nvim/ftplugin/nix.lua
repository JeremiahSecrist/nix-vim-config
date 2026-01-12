-- Exit if nixd isn't available
if vim.fn.executable("nixd") ~= 1 then
  return
end

local root_files = {
  "flake.nix",
  "default.nix",
  "shell.nix",
  ".git",
}

local root = vim.fs.find(root_files, { upward = true })[1]
if root then
  root = vim.fs.dirname(root)
end

vim.lsp.start({
  name = "nixd",
  cmd = { "nixd" },
  root_dir = root or vim.loop.cwd(),
  capabilities = require("user.lsp").make_client_capabilities(),
  settings = {
  nixd = {
    nixpkgs = {
      expr = "import (builtins.getFlake \"nixpkgs\") {}",
    },
    options = {
      enable = true,
      target = {
        installable = ".#nixosConfigurations.${HOSTNAME}.options",
      },
    },
  },
},
})

