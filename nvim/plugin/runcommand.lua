local Terminal = require('toggleterm.terminal').Terminal

-- File type to command mapping
local file_runners = {
  javascript = "node",
  typescript = "node", -- You might want to use ts-node instead
  python = "python",   -- Changed from python3 to python for better direnv compatibility
  lua = "lua",
  go = "go run",
  rust = "cargo run", -- For single files, you might want to use rustc instead
  java = "java", -- Note: Java requires compilation first
  cpp = "g++ -o /tmp/temp_exec %s && /tmp/temp_exec",
  c = "gcc -o /tmp/temp_exec %s && /tmp/temp_exec",
  ruby = "ruby",
  php = "php",
  perl = "perl",
  bash = "bash",
  zsh = "zsh",
  fish = "fish",
  sh = "sh"
}

-- Function to check if we're in a direnv-managed directory
local function is_direnv_managed(filepath)
  -- Start from the file's directory, not the current working directory
  local file_dir = vim.fn.fnamemodify(filepath or vim.fn.expand("%:p"), ":h")
  local path = file_dir
  
  while path ~= "/" do
    if vim.fn.filereadable(path .. "/.envrc") == 1 then
      return true, path
    end
    path = vim.fn.fnamemodify(path, ":h")
  end
  
  return false, nil
end

-- Function to get environment from direnv for a specific directory
local function get_direnv_env(direnv_root)
  -- Change to the direnv directory to get the correct environment
  local original_dir = vim.fn.getcwd()
  local success, err = pcall(function()
    vim.cmd("cd " .. vim.fn.fnameescape(direnv_root))
  end)
  
  if not success then
    vim.notify("Failed to change to direnv directory: " .. tostring(err), vim.log.levels.ERROR)
    return {}
  end
  
  -- Use direnv exec to get the environment instead of export
  local handle = io.popen("direnv exec . env 2>/dev/null")
  if not handle then
    vim.cmd("cd " .. vim.fn.fnameescape(original_dir))
    return {}
  end
  
  local result = handle:read("*a")
  handle:close()
  
  -- Change back to original directory
  vim.cmd("cd " .. vim.fn.fnameescape(original_dir))
  
  if result == "" then
    return {}
  end
  
  -- Parse environment variables from env output
  local env = {}
  for line in result:gmatch("[^\r\n]+") do
    local key, value = line:match("^([^=]+)=(.*)$")
    if key and value then
      env[key] = value
    end
  end
  
  return env
end

-- Function to create environment string for terminal command
local function create_env_string(env_vars)
  local env_parts = {}
  
  -- Important: Only include variables that are different from the current environment
  -- or are commonly overridden by direnv
  local important_env_vars = {
    "PATH", "PYTHONPATH", "NODE_PATH", "GOPATH", "JAVA_HOME", 
    "LD_LIBRARY_PATH", "PKG_CONFIG_PATH", "VIRTUAL_ENV",
    "NODE_ENV", "PYTHON_PATH", "GEM_PATH", "GEM_HOME",
    "CARGO_HOME", "RUSTUP_HOME", "GOBIN", "GOROOT"
  }
  
  for _, key in ipairs(important_env_vars) do
    local value = env_vars[key]
    if value and value ~= "" then
      -- Properly escape the value
      local escaped_value = value:gsub('"', '\\"'):gsub('`', '\\`'):gsub('$', '\\$')
      table.insert(env_parts, string.format('%s="%s"', key, escaped_value))
    end
  end
  
  if #env_parts > 0 then
    return table.concat(env_parts, " ") .. " "
  else
    return ""
  end
end

-- Function to get the appropriate runner command
local function get_runner_command(filetype, filepath)
  local runner = file_runners[filetype]
  if not runner then
    vim.notify("No runner configured for filetype: " .. filetype, vim.log.levels.WARN)
    return nil
  end
  
  -- Check if we're in a direnv-managed directory based on the file's location
  local is_direnv, direnv_root = is_direnv_managed(filepath)
  local env_prefix = ""
  
  if is_direnv then
    local direnv_env = get_direnv_env(direnv_root)
    env_prefix = create_env_string(direnv_env)
    
    if env_prefix ~= "" then
      vim.notify("Using direnv environment from: " .. direnv_root, vim.log.levels.INFO)
    end
  end
  
  -- Handle special cases where we need different formatting
  local base_cmd
  if filetype == "java" then
    -- For Java, we need to compile first, then run
    local classname = vim.fn.fnamemodify(filepath, ":t:r")
    base_cmd = string.format("javac %s && java %s", filepath, classname)
  elseif filetype == "rust" then
    -- Check if we're in a Cargo project (look from file's directory)
    local file_dir = vim.fn.fnamemodify(filepath, ":h")
    local cargo_toml = vim.fn.findfile("Cargo.toml", file_dir .. ";")
    if cargo_toml ~= "" then
      -- Change to the directory containing Cargo.toml
      local cargo_dir = vim.fn.fnamemodify(cargo_toml, ":h")
      base_cmd = string.format("cd %s && cargo run", vim.fn.fnameescape(cargo_dir))
    else
      -- For standalone Rust files
      local output = "/tmp/" .. vim.fn.fnamemodify(filepath, ":t:r")
      base_cmd = string.format("rustc %s -o %s && %s", filepath, output, output)
    end
  elseif filetype == "python" then
    -- For Python, prefer the python from the environment
    base_cmd = string.format("%s %s", runner, filepath)
  elseif filetype == "typescript" then
    -- Check if ts-node is available, otherwise use node
    local has_ts_node = vim.fn.executable("ts-node") == 1
    if has_ts_node then
      base_cmd = string.format("ts-node %s", filepath)
    else
      -- Try to compile with tsc first if available
      local has_tsc = vim.fn.executable("tsc") == 1
      if has_tsc then
        local js_file = filepath:gsub("%.ts$", ".js")
        base_cmd = string.format("tsc %s && node %s", filepath, js_file)
      else
        base_cmd = string.format("node %s", filepath)
      end
    end
  else
    base_cmd = string.format("%s %s", runner, filepath)
  end
  
  -- For commands that need to run in the file's directory (like Node.js with relative imports)
  local file_dir = vim.fn.fnamemodify(filepath, ":h")
  local filename = vim.fn.fnamemodify(filepath, ":t")
  
  -- Always run from the file's directory for better context
  if filetype == "javascript" or filetype == "typescript" or filetype == "python" then
    -- Use direnv exec to run the command with the proper environment
    if is_direnv then
      base_cmd = string.format("cd %s && direnv exec %s %s %s", 
        vim.fn.fnameescape(file_dir), 
        vim.fn.fnameescape(direnv_root), 
        runner, 
        filename)
      env_prefix = "" -- Don't need env_prefix when using direnv exec
    else
      base_cmd = string.format("cd %s && %s %s", vim.fn.fnameescape(file_dir), runner, filename)
    end
  else
    -- For other languages, use the original approach
    if is_direnv then
      base_cmd = string.format("direnv exec %s %s", vim.fn.fnameescape(direnv_root), base_cmd)
      env_prefix = "" -- Don't need env_prefix when using direnv exec
    end
  end
  
  -- Combine environment prefix with the base command (only if not using direnv exec)
  return env_prefix .. base_cmd
end

-- Create a floating terminal for running files
local function run_current_file()
  local filepath = vim.fn.expand("%:p")
  local filename = vim.fn.expand("%:t")
  local filetype = vim.bo.filetype
  
  -- Check if file exists and is saved
  if vim.fn.filereadable(filepath) == 0 then
    vim.notify("File does not exist or is not readable", vim.log.levels.ERROR)
    return
  end
  
  -- Check if buffer has unsaved changes
  if vim.bo.modified then
    vim.notify("Please save the file first", vim.log.levels.WARN)
    return
  end
  
  local cmd = get_runner_command(filetype, filepath)
  if not cmd then
    return
  end
  
  -- Create or reuse a floating terminal
  local float_term = Terminal:new({
    cmd = cmd,
    direction = "float",
    float_opts = {
      border = "curved",
      width = math.floor(vim.o.columns * 0.8),
      height = math.floor(vim.o.lines * 0.8),
    },
    close_on_exit = false, -- Keep terminal open to see output
    on_open = function(term)
      -- Set some convenient keymaps for the terminal
      vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<Esc>", "<C-\\><C-n>", {noremap = true, silent = true})
      vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<C-\\>", "<cmd>close<CR>", {noremap = true, silent = true})
      vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
      vim.api.nvim_buf_set_keymap(term.bufnr, "n", "<leader>q", "<cmd>close<CR>", {noremap = true, silent = true})
      vim.api.nvim_buf_set_keymap(term.bufnr, "n", "<C-\\>", "<cmd>close<CR>", {noremap = true, silent = true})
      
      -- Show which environment we're using (based on file location)
      local filepath = vim.fn.expand("%:p")
      local is_direnv, direnv_root = is_direnv_managed(filepath)
      if is_direnv then
        print("Running with direnv environment from: " .. direnv_root)
      end
    end,
  })
  
  float_term:toggle()
end

-- Function to reload direnv manually
local function reload_direnv()
  local filepath = vim.fn.expand("%:p")
  local is_direnv, direnv_root = is_direnv_managed(filepath)
  if not is_direnv then
    vim.notify("No .envrc found for current file directory tree", vim.log.levels.WARN)
    return
  end
  
  -- Run direnv allow to reload the environment in the correct directory
  local cmd_string = "cd " .. vim.fn.fnameescape(direnv_root) .. " && direnv allow && echo \"Direnv reloaded successfully\""
  local reload_term = Terminal:new({
    cmd = cmd_string,
    direction = "float",
    float_opts = {
      border = "curved",
      width = 60,
      height = 10,
    },
    close_on_exit = false,
  })
  
  reload_term:toggle()
  vim.notify("Reloading direnv environment from: " .. direnv_root, vim.log.levels.INFO)
end

-- Key mappings
vim.keymap.set("n", "<A-r>", run_current_file, { desc = "Run current file" })
vim.keymap.set("n", "<leader>dr", reload_direnv, { desc = "Reload direnv environment" })

-- Commands
vim.api.nvim_create_user_command("RunFile", run_current_file, { desc = "Run the current file" })
vim.api.nvim_create_user_command("ReloadDirenv", reload_direnv, { desc = "Reload direnv environment" })

-- Optional: Add a function to add custom runners
local function add_runner(filetype, command)
  file_runners[filetype] = command
  vim.notify(string.format("Added runner for %s: %s", filetype, command), vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("AddRunner", function(opts)
  local args = vim.split(opts.args, " ", { plain = true })
  if #args < 2 then
    vim.notify("Usage: :AddRunner <filetype> <command>", vim.log.levels.ERROR)
    return
  end
  local filetype = args[1]
  local command = table.concat(vim.list_slice(args, 2), " ")
  add_runner(filetype, command)
end, { 
  desc = "Add a custom runner for a filetype",
  nargs = "+",
  complete = function()
    return vim.fn.getcompletion("", "filetype")
  end
})

-- Function to show current environment info
local function show_env_info()
  local filepath = vim.fn.expand("%:p")
  local is_direnv, direnv_root = is_direnv_managed(filepath)
  if is_direnv then
    vim.notify("Direnv detected at: " .. direnv_root .. " (for current file)", vim.log.levels.INFO)
    
    -- Show some key environment variables
    local direnv_env = get_direnv_env(direnv_root)
    local important_vars = {"PATH", "PYTHON_PATH", "NODE_PATH", "GOPATH", "JAVA_HOME"}
    
    for _, var in ipairs(important_vars) do
      if direnv_env[var] then
        print(var .. ": " .. (direnv_env[var]:sub(1, 50) .. (direnv_env[var]:len() > 50 and "..." or "")))
      end
    end
  else
    vim.notify("No direnv environment detected for current file", vim.log.levels.INFO)
  end
end

vim.api.nvim_create_user_command("ShowEnvInfo", show_env_info, { desc = "Show current environment information" })
