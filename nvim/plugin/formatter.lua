local util = require "formatter.util"

local biome_path = vim.fn.exepath("biome")
if biome_path == "" then
    vim.notify("Biome not found in PATH", vim.log.levels.WARN)
    return
end

local function biome_formatter()
    local filepath = util.get_current_buffer_file_path()
    return {
        exe = biome_path,
        args = { "format", "--stdin-file-path", util.escape_path(filepath) },  -- fixed
        stdin = true
    }
end

require("formatter").setup({
    logging = true,
    log_level = vim.log.levels.WARN,
    filetype = {
        javascript = { biome_formatter },
        javascriptreact = { biome_formatter },
        typescript = { biome_formatter },
        typescriptreact = { biome_formatter },
    }
})

vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = {"*.js","*.ts","*.tsx","*.jsx"},
    callback = function()
        vim.cmd("Format")
    end
})
