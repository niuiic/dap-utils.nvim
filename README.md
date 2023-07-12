# dap-utils.nvim

A simple plugin to inject custom operations before start debugging.

Here is an example to debug rust in a workspace.

```lua
require("dap-utils").setup({
	rust = function(run)
		-- nvim-dap start to work after call `run`
		-- the arguments of `run` is same to `dap.run`, see :h dap-api.
		local config = {
			name = "Launch",
			type = "lldb",
			request = "launch",
			program = nil,
			cwd = "${workspaceFolder}",
			stopOnEntry = false,
			args = {},
		}
		local core = require("niuiic-core")
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
