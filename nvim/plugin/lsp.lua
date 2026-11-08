if vim.g.did_load_lsp_plugin then
  return
end
vim.g.did_load_lsp_plugin = true

local lsp = require('user.lsp')

-- The bundled nvim 0.11 runtime has no filetype detection for .typst
vim.filetype.add {
  extension = {
    typst = 'typst',
  },
}

-- Defaults applied to every language server.
-- Server configs themselves come from nvim-lspconfig's lsp/ runtime files,
-- so filetypes and root_dir detection are handled automatically.
vim.lsp.config('*', {
  capabilities = lsp.make_client_capabilities(),
})

-- Candidate language servers. Each one is enabled automatically when its
-- binary is available from a devshell, the system, or the bundled nix
-- packages (in that order of preference). Servers whose binary cannot be
-- found are simply not enabled.
--
-- `bin`   - the executable name
-- `args`  - extra cmd arguments (cmd defaults to { bin, unpack(args) })
-- `cmd`   - optional function(bin) -> cmd; overrides args handling
-- `requires` - other binaries that must also be resolvable (e.g. toolchains
--              the server shells out to); the server is skipped without them
-- `config`- extra config merged into the server's lspconfig defaults
local candidates = {
  -- Bundled in extraPackages, also picked up from a devshell/system
  lua_ls = {
    bin = 'lua-language-server',
    config = {
      settings = {
        Lua = {
          runtime = {
            version = 'LuaJIT',
          },
          diagnostics = {
            -- Get the language server to recognize the `vim` global, etc.
            globals = {
              'vim',
              'describe',
              'it',
              'assert',
              'stub',
            },
            disable = {
              'duplicate-set-field',
            },
          },
          workspace = {
            checkThirdParty = false,
          },
          telemetry = {
            enable = false,
          },
          hint = { -- inlay hints (supported in Neovim >= 0.10)
            enable = true,
          },
        },
      },
    },
  },
  nixd = {
    bin = 'nixd',
    config = {
      settings = {
        nixd = {
          nixpkgs = {
            expr = 'import (builtins.getFlake "nixpkgs") {}',
          },
          options = {
            enable = true,
            target = {
              installable = '.#nixosConfigurations.${HOSTNAME}.options',
            },
          },
        },
      },
    },
  },
  ts_ls = {
    bin = 'typescript-language-server',
    args = { '--stdio' },
  },
  tinymist = {
    bin = 'tinymist',
    config = {
      settings = {
        formatterMode = 'typstyle',
        exportPdf = 'onType',
        semanticTokens = 'disable',
      },
      auto_archive = false, -- Disable autoArchive prompt
    },
  },
  biome = {
    bin = 'biome',
    cmd = function(bin)
      return function(dispatchers, config)
        local cmd = bin
        local local_cmd = (config or {}).root_dir and config.root_dir .. '/node_modules/.bin/biome'
        if local_cmd and vim.fn.executable(local_cmd) == 1 then
          cmd = local_cmd
        end
        return vim.lsp.rpc.start({ cmd, 'lsp-proxy' }, dispatchers)
      end
    end,
  },

  -- Not bundled: activated by a devshell or system install
  -- gopls shells out to `go env` and rust_analyzer to `cargo metadata`
  -- during root detection, so they need their toolchains too
  gopls = { bin = 'gopls', requires = { 'go' } },
  rust_analyzer = { bin = 'rust-analyzer', requires = { 'cargo' } },
  pyright = { bin = 'pyright-langserver' },
  basedpyright = { bin = 'basedpyright-langserver' },
  clangd = { bin = 'clangd' },
  -- The language server is the `gleam lsp` subcommand, not a separate binary.
  gleam = { bin = 'gleam', args = { 'lsp' } },
  bashls = { bin = 'bash-language-server' },
  marksman = { bin = 'marksman' },
  dockerls = { bin = 'docker-langserver' },
  jsonls = { bin = 'vscode-json-language-server', args = { '--stdio' } },
  yamlls = { bin = 'yaml-language-server', args = { '--stdio' } },
}

local function available(spec)
  if not lsp.resolve_bin(spec.bin) then
    return false
  end
  for _, req in ipairs(spec.requires or {}) do
    if not lsp.resolve_bin(req) then
      return false
    end
  end
  return true
end

local enabled = {}
for name, spec in pairs(candidates) do
  local bin = available(spec) and lsp.resolve_bin(spec.bin) or nil
  if bin then
    local cfg = vim.tbl_deep_extend('force', {}, spec.config or {})
    cfg.cmd = spec.cmd and spec.cmd(bin) or vim.list_extend({ bin }, spec.args or {})
    vim.lsp.config(name, cfg)
    table.insert(enabled, name)
  end
end

if #enabled > 0 then
  vim.lsp.enable(enabled)
end
