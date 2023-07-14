local static = require("dap-utils.static")
local core = require("niuiic-core")

local run = function(config, option)
	local dap = require("dap")
	if not config.name then
		for _, value in pairs(config) do
			if not value.name then
				vim.notify("Wrong config", vim.log.levels.ERROR, { title = "Dap" })
				return
			end
		end
		local methods = core.lua.list.map(config, function(v)
			return v.name
		end)
		vim.ui.select(methods, { prompt = "Select Debug Method" }, function(choice)
			if not choice then
				return
			end
			local conf = core.lua.list.find(config, function(v)
				return v.name == choice
			end)
			dap.run(conf, option)
		end)
	else
		dap.run(config, option)
	end
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
		config(run)
	else
		dap.continue()
	end
end

return continue
