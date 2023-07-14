local core = require("core")

local add_to_watch = function()
	require("dapui").elements.watches.add(core.text.selection())
end

return {
	add_to_watch = add_to_watch,
}
