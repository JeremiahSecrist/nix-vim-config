-- Track last accessed buffer
local last_buf = nil

-- Update last_buf on BufEnter
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    if last_buf ~= bufnr then
      last_buf = bufnr
    end
  end,
})

-- Force-close current buffer, switch to last used
function ForceCloseBuffer()
  local current = vim.api.nvim_get_current_buf()
  local buffers = vim.fn.getbufinfo({buflisted = 1})

  if #buffers > 1 then
    -- Remove current buffer
    vim.api.nvim_buf_delete(current, {force = true})

    -- Find a valid buffer to switch to
    for _, buf in ipairs(buffers) do
      if buf.bufnr ~= current and vim.api.nvim_buf_is_valid(buf.bufnr) then
        vim.api.nvim_set_current_buf(buf.bufnr)
        break
      end
    end
  else
    vim.cmd("qa!")
  end
end

-- Create a user command BQ with a description
vim.api.nvim_create_user_command("BQ", ForceCloseBuffer, {
  desc = "Force close the current buffer and switch to last accessed buffer"
})

-- Map <leader>q to ForceCloseBuffer with a description
vim.api.nvim_set_keymap('n', '<leader>qq', ':lua ForceCloseBuffer()<CR>', {
  noremap = true,
  silent = true,
  desc = "Force close the current buffer and switch to last accessed buffer"
})

