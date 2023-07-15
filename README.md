# dap-utils.nvim

Utilties to provide a better experience for using `nvim-dap`.

## Dependencies

- [niuiic/core.nvim](https://github.com/niuiic/core.nvim)

## Usage

### continue

- Safely inject custom operations before start debugging.
- Replace the original `continue` with `require("dap-utils").continue()`, and start to debug with this function.

> Async functions or some ui operations may cause error if they are called in `program` function.

### store_breakpoints

- Store all breakpoints to a file.
- `require("dap-utils").store_breakpoints(file_path, root_pattern)`
- `root_pattern` is `.git` by default.

> Use it with a session manager, see [niuiic/multiple-session.nvim](https://github.com/niuiic/multiple-session.nvim).

### restore_breakpoints

- Restore all breakpoints from a file.
- `require("dap-utils").restore_breakpoints(file_path, root_pattern)`
- `root_pattern` is `.git` by default.

### store_watches

- Store all watches to a file.
- `require("dap-utils").store_watches(file_path)`

### restore_watches

- Restore all watches from a file.
- `require("dap-utils").restore_watches(file_path)`

## Config

Here is an example to debug rust in a workspace.

```lua
require("dap-utils").setup({
	-- filetype = function while returns dap config
	rust = function(run)
		-- nvim-dap start to work after call `run`
		-- the arguments of `run` is same to `dap.run`, see :h dap-api.
		local config = {
			-- `name` is required for config
			name = "Launch",
			type = "lldb",
			request = "launch",
			program = nil,
			cwd = "${workspaceFolder}",
			stopOnEntry = false,
			args = {},
		}
		local core = require("core")
		vim.cmd("!cargo build")
		local root_path = core.file.root_path()
		local target_dir = root_path .. "/target/debug/"
		if core.file.file_or_dir_exists(target_dir) then
			local executable = {}
			for path, path_type in vim.fs.dir(target_dir) do
				if path_type == "file" then
					local perm = vim.fn.getfperm(target_dir .. path)
					if string.match(perm, "x", 3) then
						table.insert(executable, path)
					end
				end
			end
			if #executable == 1 then
				config.program = target_dir .. executable[1]
				run(config)
			else
				vim.ui.select(executable, { prompt = "Select executable" }, function(choice)
					if not choice then
						return
					end
					config.program = target_dir .. choice
					run(config)
				end)
			end
		else
			vim.ui.input({ prompt = "Path to executable: ", default = root_path .. "/target/debug/" }, function(input)
				config.program = input
				run(config)
			end)
		end
	end,
})
```

You can also pass multiple configurations into `run`.

```lua
require("dap-utils").setup({
	javascript = function(run)
		local core = require("core")
		run({
			{
				name = "Launch project",
				type = "pwa-node",
				request = "launch",
				cwd = "${workspaceFolder}",
				runtimeExecutable = "pnpm",
				runtimeArgs = {
					"debug",
				},
			},
			{
				name = "Launch cmd",
				type = "pwa-node",
				request = "launch",
				cwd = core.file.root_path(),
				runtimeExecutable = "pnpm",
				runtimeArgs = {
					"debug:cmd",
				},
			},
			{
				name = "Launch file",
				type = "pwa-node",
				request = "launch",
				program = "${file}",
				cwd = "${workspaceFolder}",
			},
			{
				name = "Attach",
				type = "pwa-node",
				request = "attach",
				processId = require("dap.utils").pick_process,
				cwd = "${workspaceFolder}",
			},
		})
	end,
})
```
