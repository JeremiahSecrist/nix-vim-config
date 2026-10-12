---@mod user.lsp
---
---@brief [[
---LSP related functions
---@brief ]]

local M = {}

-- Bin dirs of the nix-wrapped packages, baked in by mkNeovim.nix.
-- The wrapper prepends these to PATH, so they would normally shadow
-- binaries from a devshell or the system. We skip them when resolving.
local bundled_bin_dirs = {}
for _, dir in ipairs(vim.split(vim.env.NVIM_BUNDLED_BINS or '', ':', { plain = true })) do
  if dir ~= '' then
    bundled_bin_dirs[dir] = true
  end
end

---Resolve an executable. Prefers a system/devshell binary over the
---bundled nix one, then falls back to the bundled packages.
---@param name string
---@return string|nil
function M.resolve_bin(name)
  -- System/devshell (any non-bundled PATH entry)
  for _, dir in ipairs(vim.split(vim.env.PATH or '', ':', { plain = true })) do
    if dir ~= '' and not bundled_bin_dirs[dir] then
      local candidate = dir .. '/' .. name
      if vim.fn.executable(candidate) == 1 then
        return candidate
      end
    end
  end
  -- Bundled nix packages
  for dir in pairs(bundled_bin_dirs) do
    local candidate = dir .. '/' .. name
    if vim.fn.executable(candidate) == 1 then
      return candidate
    end
  end
end

---Like resolve_bin, but falls back to the bare name (resolved via the
---wrapped PATH at spawn time) when nothing is found.
---@param name string
---@return string
function M.system_bin(name)
  return M.resolve_bin(name) or name
end

---Gets a 'ClientCapabilities' object, describing the LSP client capabilities
---Extends the object with capabilities provided by plugins.
---@return lsp.ClientCapabilities
function M.make_client_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  -- Add com_nvim_lsp capabilities
  local cmp_lsp = require('cmp_nvim_lsp')
  local cmp_lsp_capabilities = cmp_lsp.default_capabilities()
  capabilities = vim.tbl_deep_extend('keep', capabilities, cmp_lsp_capabilities)
  -- Add any additional plugin capabilities here.
  -- Make sure to follow the instructions provided in the plugin's docs.
  return capabilities
end

return M
