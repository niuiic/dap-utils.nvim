local static = require("dap-utils.static")
local continue = require("dap-utils.continue")
local breakpoint = require("dap-utils.breakpoint")
local watch = require("dap-utils.watch")

local setup = function(new_config)
	static.config = vim.tbl_deep_extend("force", static.config, new_config or {})
end

return {
	setup = setup,
	continue = continue,
	store_breakpoints = breakpoint.store_breakpoints,
	restore_breakpoints = breakpoint.restore_breakpoints,
	search_breakpoints = breakpoint.search_breakpoints,
	toggle_breakpoints = breakpoint.toggle_breakpoints,
	clear_breakpoints = breakpoint.clear_breakpoints,
	store_watches = watch.store_watches,
	restore_watches = watch.restore_watches,
	remove_watches = watch.remove_watches,
}
