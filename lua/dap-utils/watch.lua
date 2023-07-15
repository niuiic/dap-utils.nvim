local core = require("core")

local store_watches = function(file_path)
	local watches = require("dapui").elements.watches.get()
	print(vim.inspect(watches))

	local text = vim.fn.json_encode(watches)

	local file = io.open(file_path, "w+")
	if not file then
		return
	end
	file:write(text)
	file:close()
end

local restore_watches = function(file_path)
	if not core.file.file_or_dir_exists(file_path) then
		return
	end
	local file = io.open(file_path, "r")
	if not file then
		return
	end
	local text = file:read("*a")

	local watches = vim.fn.json_decode(text)
	if watches == nil then
		return
	end

	core.lua.list.each(watches, function(watch, i)
		require("dapui").elements.watches.add(watch.expression)
		if watch.expanded then
			require("dapui").elements.watches.toggle_expand(i)
		end
	end)
end

return {
	store_watches = store_watches,
	restore_watches = restore_watches,
}
