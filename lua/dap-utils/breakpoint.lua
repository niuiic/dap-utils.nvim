local core = require("niuiic-core")

local get_buf_name = function(bufnr, root_path)
	return string.sub(vim.api.nvim_buf_get_name(bufnr), string.len(root_path) + 2)
end

local store_breakpoints = function(file_path, root_pattern)
	local root_path = core.file.root_path(root_pattern)

	local breakpoints = require("dap.breakpoints").get()
	breakpoints = core.lua.table.reduce(breakpoints, function(prev_res, cur_item)
		local buf_name = get_buf_name(cur_item.k, root_path)
		prev_res[buf_name] = cur_item.v
		return prev_res
	end, {})

	local text = vim.fn.json_encode(breakpoints)

	local file = io.open(file_path, "w+")
	if not file then
		return
	end
	file:write(text)
	file:close()
end

local restore_breakpoints = function(file_path, root_pattern)
	local root_path = core.file.root_path(root_pattern)

	if not core.file.file_or_dir_exists(file_path) then
		return
	end
	local file = io.open(file_path, "r")
	if not file then
		return
	end
	local text = file:read("*a")

	local breakpoints = vim.fn.json_decode(text)
	if breakpoints == nil then
		return
	end
	breakpoints = core.lua.list.reduce(vim.api.nvim_list_bufs(), function(prev_res, cur_item)
		local buf_name = get_buf_name(cur_item, root_path)
		if breakpoints[buf_name] ~= nil then
			prev_res[cur_item] = breakpoints[buf_name]
		end
		return prev_res
	end, {})

	core.lua.table.each(breakpoints, function(bufnr, breakpoint)
		core.lua.list.each(breakpoint, function(v)
			require("dap.breakpoints").set({
				condition = v.condition,
				log_message = v.logMessage,
				hit_condition = v.hitCondition,
			}, tonumber(bufnr), v.line)
		end)
	end)
end

return {
	store_breakpoints = store_breakpoints,
	restore_breakpoints = restore_breakpoints,
}
