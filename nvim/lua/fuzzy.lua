local M = {}

local function fuzzy_find(items, pattern)
	if not pattern or pattern == "" then
		return items
	end

	local pattern_parts = {}
	for word in vim.gsplit(pattern, "%s+") do
		table.insert(pattern_parts, word:lower())
	end

	local filtered = {}
	for _, item in ipairs(items) do
		local text = item.text:lower()
		local match = true
		for _, part in ipairs(pattern_parts) do
			if not text:find(part, 1, true) then
				match = false
				break
			end
		end
		if match then
			table.insert(filtered, item)
		end
	end

	return filtered
end

local function get_buffers(callback)
	local buffers = vim.api.nvim_list_bufs()
	local items = {}

	for _, buf in ipairs(buffers) do
		if vim.api.nvim_buf_is_valid(buf) then
			local name = vim.api.nvim_buf_get_name(buf)
			if name and name ~= "" then
				local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
				table.insert(items, {
					text = vim.fn.fnamemodify(name, ":t"),
					full_path = name,
					filetype = filetype,
					buf = buf,
				})
			end
		end
	end

	callback(items)
end

local function get_files(cwd, callback)
	local cmd = { "find", cwd, "-maxdepth", "4", "-type", "f", "-not", "-path", "*/.git/*" }
	vim.system(cmd, { text = true }, function(obj)
		local items = {}
		if obj.code == 0 then
			for _, line in ipairs(vim.split(obj.stdout, "\n")) do
				local trimmed = vim.trim(line)
				if trimmed ~= "" then
					local filename = vim.fn.fnamemodify(trimmed, ":t")
					table.insert(items, {
						text = filename,
						full_path = trimmed,
					})
				end
			end
		end
		vim.schedule(function()
			callback(items)
		end)
	end)
end

local function get_git_files(callback)
	vim.system({ "git", "ls-files", "--others", "--exclude-standard" }, { text = true }, function(obj)
		local items = {}
		if obj.code == 0 then
			for _, line in ipairs(vim.split(obj.stdout, "\n")) do
				local trimmed = vim.trim(line)
				if trimmed ~= "" then
					table.insert(items, {
						text = trimmed,
						full_path = trimmed,
					})
				end
			end
		end
		vim.schedule(function()
			callback(items)
		end)
	end)
end

local function get_recent_files(callback)
	local items = {}
	local recent = vim.v.oldfiles
	for _, path in ipairs(recent) do
		if vim.fn.filereadable(path) == 1 then
			table.insert(items, {
				text = vim.fn.fnamemodify(path, ":t"),
				full_path = path,
			})
		end
		if #items >= 50 then
			break
		end
	end
	callback(items)
end

local function get_commands(callback)
	local items = {}
	local commands = vim.api.nvim_get_commands({})
	for _, cmd in ipairs(commands) do
		table.insert(items, {
			text = cmd.name,
			desc = cmd.description or "",
			command = cmd.name,
		})
	end
	callback(items)
end

local function get_keymaps(mode, callback)
	local items = {}
	local maps = vim.api.nvim_get_keymap(mode)
	for _, map in ipairs(maps) do
		local lhs = map.lhs
		local rhs = map.rhs or ""
		local desc = map.desc or ""
		table.insert(items, {
			text = lhs,
			rhs = rhs,
			desc = desc,
			mode = mode,
		})
	end
	callback(items)
end

local function get_help_tags(callback)
	local items = {}
	local help_dir = vim.fn.stdpath("data") .. "/doc"
	vim.system({ "ls", help_dir }, { text = true }, function(obj)
		if obj.code == 0 then
			for _, line in ipairs(vim.split(obj.stdout, "\n")) do
				local trimmed = vim.trim(line)
				if trimmed:match("%.txt$") then
					local tag_name = trimmed:gsub("%.txt$", "")
					table.insert(items, {
						text = tag_name,
						tag = tag_name,
					})
				end
			end
		end
		vim.schedule(function()
			callback(items)
		end)
	end)
end

local function get_grep_results(pattern, callback)
	vim.system({ "rg", "--files", "--glob", "!.git" }, { text = true }, function(obj)
		local items = {}
		if obj.code == 0 then
			for _, line in ipairs(vim.split(obj.stdout, "\n")) do
				local trimmed = vim.trim(line)
				if trimmed ~= "" then
					table.insert(items, {
						text = trimmed,
						full_path = trimmed,
					})
				end
			end
		end
		vim.schedule(function()
			callback(items)
		end)
	end)
end

local function open_buffer(item)
	vim.cmd("edit " .. item.full_path)
end

local function run_command(item)
	vim.cmd(item.command)
end

local function show_help(item)
	vim.cmd("help " .. item.tag)
end

local function do_fuzzy(prompt, items, on_select)
	require("snacks").picker({
		title = prompt,
		items = items,
		format = function(item, _)
			return {
				{ item.text, "SnacksPickerTitle" },
			}
		end,
		layout = { preset = "default" },
		confirm = function(self, item)
			if item then
				self:close()
				on_select(item)
			end
		end,
	})
end

function M.pick()
	local items = {
		{ text = "Files", icon = "󰈔", action = "files" },
		{ text = "Git Files", icon = "󰊢", action = "git_files" },
		{ text = "Buffers", icon = "󰈙", action = "buffers" },
		{ text = "Recent Files", icon = "󰈉", action = "recent" },
		{ text = "Commands", icon = "󰘧", action = "commands" },
		{ text = "Keymaps (Normal)", icon = "󰌌", action = "keymaps_n" },
		{ text = "Keymaps (Insert)", icon = "󰌫", action = "keymaps_i" },
		{ text = "Keymaps (Visual)", icon = "󰍜", action = "keymaps_v" },
		{ text = "Help Tags", icon = "󰞋", action = "help" },
		{ text = "Grep (ripgrep)", icon = "󰊄", action = "grep" },
	}

	require("snacks").picker({
		title = "Fuzzy Finder",
		items = items,
		format = function(item, _)
			return {
				{ item.icon, "SnacksPickerIcon" },
				{ " " },
				{ item.text, "SnacksPickerTitle" },
			}
		end,
		layout = { preset = "default" },
		confirm = function(self, item)
			if not item then
				return
			end
			self:close()

			if item.action == "files" then
				get_files(vim.fn.getcwd(), function(all_items)
					do_fuzzy("Files", all_items, open_buffer)
				end)
			elseif item.action == "git_files" then
				get_git_files(function(all_items)
					do_fuzzy("Git Files", all_items, open_buffer)
				end)
			elseif item.action == "buffers" then
				get_buffers(function(all_items)
					local formatted = {}
					for _, b in ipairs(all_items) do
						table.insert(formatted, {
							text = b.text .. " (" .. b.filetype .. ")",
							full_path = b.full_path,
						})
					end
					do_fuzzy("Buffers", formatted, open_buffer)
				end)
			elseif item.action == "recent" then
				get_recent_files(function(all_items)
					do_fuzzy("Recent Files", all_items, open_buffer)
				end)
			elseif item.action == "commands" then
				get_commands(function(all_items)
					local formatted = {}
					for _, c in ipairs(all_items) do
						table.insert(formatted, {
							text = c.text .. " - " .. c.desc,
							command = c.command,
						})
					end
					do_fuzzy("Commands", formatted, run_command)
				end)
			elseif item.action == "keymaps_n" then
				get_keymaps("n", function(all_items)
					local formatted = {}
					for _, m in ipairs(all_items) do
						table.insert(formatted, {
							text = m.text .. " → " .. m.rhs,
						})
					end
					do_fuzzy("Normal Keymaps", formatted, function()
					end)
				end)
			elseif item.action == "keymaps_i" then
				get_keymaps("i", function(all_items)
					local formatted = {}
					for _, m in ipairs(all_items) do
						table.insert(formatted, {
							text = m.text .. " → " .. m.rhs,
						})
					end
					do_fuzzy("Insert Keymaps", formatted, function()
					end)
				end)
			elseif item.action == "keymaps_v" then
				get_keymaps("v", function(all_items)
					local formatted = {}
					for _, m in ipairs(all_items) do
						table.insert(formatted, {
							text = m.text .. " → " .. m.rhs,
						})
					end
					do_fuzzy("Visual Keymaps", formatted, function()
					end)
				end)
			elseif item.action == "help" then
				get_help_tags(function(all_items)
					do_fuzzy("Help Tags", all_items, show_help)
				end)
			elseif item.action == "grep" then
				vim.ui.input({ prompt = "Grep pattern: " }, function(pattern)
					if not pattern or pattern == "" then
						return
					end
					get_grep_results(pattern, function(all_items)
						do_fuzzy("Grep: " .. pattern, all_items, open_buffer)
					end)
				end)
			end
		end,
	})
end

return M
