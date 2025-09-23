local dap = require('dap')
local dapui = require('dapui')

-- DAP UI setup
dapui.setup({
  icons = { expanded = "▾", collapsed = "▸" },
  layouts = {
    {
      elements = { "scopes", "breakpoints", "stacks", "watches" },
      size = 40,
      position = "left",
    },
    {
      elements = { "repl", "console" },
      size = 0.25,
      position = "bottom",
    },
  },
  controls = { enabled = true, element = "repl" },
})

require('nvim-dap-virtual-text').setup({
  enabled = true,
  highlight_changed_variables = true,
  show_stop_reason = true,
  virt_text_pos = 'eol',
})

-- Node adapter via nix
dap.adapters['pwa-node'] = {
  type = 'server',
  host = 'localhost',
  port = '${port}',
  executable = {
    command = 'nix',
    args = { 'run', 'github:nixos/nixpkgs/nixos-25.05#vscode-js-debug', '--', '${port}' },
  }
}

-- Node script configurations
dap.configurations.javascript = {
  {
    type = 'pwa-node',
    request = 'launch',
    name = 'Launch Node Script',
    program = '${file}',
    cwd = '${workspaceFolder}',
    console = 'integratedTerminal',
  }
}
dap.configurations.typescript = dap.configurations.javascript
dap.configurations.javascriptreact = dap.configurations.javascript
dap.configurations.typescriptreact = dap.configurations.javascript

-- Auto open/close dap-ui
-- dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end
-- dap.listeners.before.event_terminated['dapui_config'] = function() dapui.close() end
-- dap.listeners.before.event_exited['dapui_config'] = function() dapui.close() end

-- Key mappings
vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start / Continue' })
vim.keymap.set('n', '<F1>', dap.step_into, { desc = 'Debug: Step Into' })
vim.keymap.set('n', '<F2>', dap.step_over, { desc = 'Debug: Step Over' })
vim.keymap.set('n', '<F3>', dap.step_out, { desc = 'Debug: Step Out' })
vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: Toggle DAP UI' })
vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
vim.keymap.set('n', '<leader>B', function()
  dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
end, { desc = 'Debug: Conditional Breakpoint' })
vim.keymap.set('n', '<F6>', dap.repl.open, { desc = 'Debug: Open REPL' })
vim.keymap.set({ 'n', 'v' }, '<leader>dh', require('dap.ui.widgets').hover, { desc = 'Debug: Hover Variables' })
vim.keymap.set({ 'n', 'v' }, '<leader>dp', require('dap.ui.widgets').preview, { desc = 'Debug: Preview Variables' })
vim.keymap.set('n', '<leader>df', function()
  local widgets = require('dap.ui.widgets')
  widgets.centered_float(widgets.frames)
end, { desc = 'Debug: Show Frames' })
vim.keymap.set('n', '<leader>ds', function()
  local widgets = require('dap.ui.widgets')
  widgets.centered_float(widgets.scopes)
end, { desc = 'Debug: Show Scopes' })
