local static = require("dap-utils.static")

local setup = function(new_config)
	static.config = vim.tbl_deep_extend("force", static.config, new_config or {})
end

local continue = function()
	local filetype = vim.api.nvim_get_option_value("filetype", {
		buf = 0,
	})
	if not filetype then
		vim.notify("Unknown filetype", vim.log.levels.ERROR, {
			title = "Dap",
		})
		return
	end
	local config = static.config[filetype]
	if not config then
		vim.notify("Unsupported filetype", vim.log.levels.ERROR, {
			title = "Dap",
		})
		return
	end
	local dap = require("dap")
	if not dap.session() then
		config(dap.run)
	else
		dap.continue()
	end
end

return {
	setup = setup,
	continue = continue,
}
