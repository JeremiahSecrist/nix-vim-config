local Terminal = require("toggleterm.terminal").Terminal
local lazygit = Terminal:new({
  cmd = "lazygit",
  hidden = true,
  direction = "float",
  float_opts = {
    border = "double",
  },
  on_open = function(term)
    -- Start in insert mode so terminal input goes directly to Lazygit
    vim.cmd("startinsert!")
    -- Forward Escape key to Lazygit instead of using it to exit terminal mode
    vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = term.bufnr, silent = true })
    -- Optionally, map <C-q> to close the terminal without interfering with Lazygit
    vim.keymap.set("t", "<C-q>", function()
      vim.cmd("close")
    end, { buffer = term.bufnr, silent = true })
  end,
})

function Lazygit_toggle()
  lazygit:toggle()
end

vim.keymap.set("n", "<leader>gg", Lazygit_toggle, { noremap = true, silent = true })
