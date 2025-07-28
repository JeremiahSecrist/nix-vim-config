local Terminal = require("toggleterm.terminal").Terminal

local lazygit = Terminal:new({
  cmd = "lazygit",
  hidden = true,
  direction = "float",
  float_opts = {
    border = "double",
  },
  on_open = function(term)
    -- Start in insert mode
    vim.cmd("startinsert!")

    -- Disable <Esc> in terminal mode (normal keymap)
    vim.api.nvim_buf_set_keymap(term.bufnr, 't', '<Esc>', '', { noremap = true, silent = true })
  end,
})

function Lazygit_toggle()
  lazygit:toggle()
end
vim.keymap.set("n", "<leader>gg", "<cmd>lua Lazygit_toggle()<CR>", {noremap = true, silent = true})
