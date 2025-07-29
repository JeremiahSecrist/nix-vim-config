local Terminal = require("toggleterm.terminal").Terminal

-- Create a new terminal for Lazygit
local lazygit = Terminal:new({
  cmd = "lazygit",
  hidden = true,
  direction = "float",
  float_opts = {
    border = "double",
  },
  on_open = function(term)
    -- Start in insert mode when the terminal opens
    vim.cmd("startinsert!")

    -- Disable <Esc> in terminal mode to prevent exiting insert mode
    vim.api.nvim_buf_set_keymap(term.bufnr, 't', '<Esc>', '', { noremap = true, silent = true })

    -- Safely remove any existing <C-l> mapping in terminal mode
    pcall(vim.api.nvim_buf_del_keymap, term.bufnr, 't', '<C-l>')
  end,
})

-- Toggle function for Lazygit
function Lazygit_toggle()
  lazygit:toggle()
end

-- Keymap to toggle Lazygit with <leader>gg
vim.keymap.set("n", "<leader>gg", "<cmd>lua Lazygit_toggle()<CR>", { noremap = true, silent = true })

