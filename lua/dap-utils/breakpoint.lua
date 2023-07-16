local core = require("core")
local method = "store"
local brks = {}

local get_buf_name = function(bufnr, root_path)
	return string.sub(vim.api.nvim_buf_get_name(bufnr), string.len(root_path) + 2)
end

local get_breakpoints = function(root_pattern)
	local root_path = core.file.root_path(root_pattern)
	local breakpoints = require("dap.breakpoints").get()

	breakpoints = core.lua.table.reduce(breakpoints, function(prev_res, cur_item)
		local buf_name = get_buf_name(cur_item.k, root_path)
		prev_res[buf_name] = cur_item.v
		return prev_res
	end, {})

	return breakpoints
end

local store_breakpoints = function(file_path, root_pattern)
	local breakpoints = get_breakpoints(root_pattern)
	if #core.lua.table.keys(breakpoints) == 0 then
		breakpoints = brks
	end

	local text = vim.fn.json_encode(breakpoints)

	local file = io.open(file_path, "w+")
	if not file then
		return
	end
	file:write(text)
	file:close()
end

local set_breakpoints = function(breakpoints, root_pattern)
	local root_path = core.file.root_path(root_pattern)

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

local restore_breakpoints = function(file_path, root_pattern)
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

	set_breakpoints(breakpoints, root_pattern)
end

local search_breakpoints = function(opts, root_pattern)
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local previewers = require("telescope.previewers")
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local winnr = vim.api.nvim_get_current_win()

	opts = opts or {}

	local breakpoints = require("dap.breakpoints").get()
	if #core.lua.table.keys(breakpoints) == 0 then
		vim.notify("No breakpoints setted", vim.log.levels.WARN)
		return
	end
	local root_path = core.file.root_path(root_pattern)
	local results = core.lua.table.reduce(breakpoints, function(prev_res, item)
		local bufnr = item.k
		local lines = item.v
		local buf_name = get_buf_name(bufnr, root_path)
		core.lua.list.each(lines, function(line)
			local line_text = vim.api.nvim_buf_get_lines(bufnr, line.line - 1, line.line, false)
			table.insert(prev_res, {
				bufnr = bufnr,
				buf_name = buf_name,
				line = line.line,
				label = string.format("%s:%s  |  %s", buf_name, line.line, line_text[1]),
			})
		end)
		return prev_res
	end, {})

	pickers
		.new(opts, {
			prompt_title = "Dap Breakpoints",
			finder = finders.new_table(core.lua.list.map(results, function(result)
				return result.label
			end)),
			sorter = conf.generic_sorter(opts),
			previewer = previewers.new_buffer_previewer({
				define_preview = function(self, entry)
					local result = core.lua.list.find(results, function(result)
						return result.label == entry[1]
					end)

					local start_line
					if result.line - 10 >= 0 then
						start_line = result.line - 10
					else
						start_line = 0
					end
					local end_line = result.line + 10

					local lines = vim.api.nvim_buf_get_lines(result.bufnr, start_line, end_line, false)
					local filetype = vim.api.nvim_get_option_value("filetype", { buf = result.bufnr })
					vim.api.nvim_set_option_value("filetype", filetype, {
						buf = self.state.bufnr,
					})
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
					vim.api.nvim_buf_add_highlight(
						self.state.bufnr,
						0,
						"TelescopeSelection",
						result.line - start_line - 1,
						0,
						-1
					)
				end,
			}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					local result = core.lua.list.find(results, function(result)
						return result.label == selection[1]
					end)
					vim.api.nvim_win_set_buf(winnr, result.bufnr)
					vim.api.nvim_win_set_cursor(winnr, {
						result.line,
						0,
					})
				end)
				return true
			end,
		})
		:find()
end

local toggle_breakpoints = function(root_pattern)
	if method == "store" then
		brks = get_breakpoints(root_pattern)
		require("dap").clear_breakpoints()
		method = "restore"
	else
		set_breakpoints(brks, root_pattern)
		method = "store"
	end
end

local clear_breakpoints = function()
	require("dap").clear_breakpoints()
	brks = {}
end

return {
	store_breakpoints = store_breakpoints,
	restore_breakpoints = restore_breakpoints,
	search_breakpoints = search_breakpoints,
	toggle_breakpoints = toggle_breakpoints,
	clear_breakpoints = clear_breakpoints,
}
