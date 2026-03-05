local M = {}

local function get_branches(callback)
	vim.system({ "git", "branch", "-a" }, { text = true }, function(obj)
		if obj.code ~= 0 then
			vim.schedule(function()
				callback("Error: " .. obj.stderr)
			end)
			return
		end

		local branches = {}
		for _, line in ipairs(vim.split(obj.stdout, "\n")) do
			local trimmed = vim.trim(line)
			if trimmed ~= "" then
				local is_current = trimmed:match("^%*")
				local name = trimmed:gsub("^%*%s*", ""):gsub("^%s*", "")
				table.insert(branches, {
					name = name,
					current = is_current ~= "",
				})
			end
		end

		vim.schedule(function()
			callback(branches)
		end)
	end)
end

local function get_current_branch(callback)
	vim.system({ "git", "branch", "--show-current" }, { text = true }, function(obj)
		vim.schedule(function()
			callback(vim.trim(obj.stdout))
		end)
	end)
end

local function checkout_branch(branch, callback)
	vim.system({ "git", "checkout", branch }, { text = true }, function(obj)
		vim.schedule(function()
			callback(obj.code == 0, obj.stdout, obj.stderr)
		end)
	end)
end

function M.switch_branch()
	get_current_branch(function(current)
		get_branches(function(branches)
			if type(branches) == "string" then
				vim.notify(branches, vim.log.levels.ERROR)
				return
			end

			local items = {}
			for _, b in ipairs(branches) do
				table.insert(items, {
					text = b.name,
					branch = b,
				})
			end

			require("snacks").picker({
				title = "Switch Branch (current: " .. (current or "none") .. ")",
				items = items,
				format = function(item, _)
					local icon = "󰊢"
					local hl = "SnacksPickerTitle"
					if item.branch.current then
						icon = "󰜤"
						hl = "SnacksPickerActive"
					elseif item.branch.name:match("^remotes/") then
						icon = "󰤤"
						hl = "SnacksPickerComment"
					end
					return {
						{ icon, "SnacksPickerIcon" },
						{ " " },
						{ item.text, hl },
					}
				end,
				layout = { preset = "default" },
				confirm = function(self, item)
					if item and item.branch then
						self:close()
						checkout_branch(item.branch.name, function(success, stdout, stderr)
							if success then
								vim.notify("Switched to: " .. item.branch.name, vim.log.levels.INFO)
								M.show_log()
							else
								vim.notify("Error: " .. (stderr or stdout), vim.log.levels.ERROR)
							end
						end)
					end
				end,
			})
		end)
	end)
end

function M.show_log()
	vim.system({ "git", "log", "--oneline", "-20" }, { text = true }, function(obj)
		vim.schedule(function()
			if obj.code ~= 0 then
				vim.notify("Error: " .. obj.stderr, vim.log.levels.ERROR)
				return
			end

			local lines = vim.split(obj.stdout, "\n")
			if #lines == 0 or (lines[1] and vim.trim(lines[1]) == "") then
				vim.notify("No commits yet", vim.log.levels.WARN)
				return
			end

			local buf = vim.api.nvim_create_buf(true, false)
			vim.api.nvim_buf_set_name(buf, "git-log")
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

			local win = vim.api.nvim_open_win(buf, true, {
				relative = "editor",
				width = math.floor(vim.o.columns * 0.7),
				height = math.floor(vim.o.lines * 0.6),
				col = math.floor(vim.o.columns * 0.15),
				row = math.floor(vim.o.lines * 0.2),
				border = "rounded",
			})

			vim.api.nvim_win_set_option(win, "wrap", true)
			vim.api.nvim_win_set_option(win, "cursorline", true)
			vim.api.nvim_buf_set_option(buf, "filetype", "git")
			vim.api.nvim_buf_set_option(buf, "modifiable", false)

			vim.keymap.set("n", "q", function()
				vim.api.nvim_win_close(win, true)
			end, { buffer = buf, silent = true })

			vim.keymap.set("n", "<Esc>", function()
				vim.api.nvim_win_close(win, true)
			end, { buffer = buf, silent = true })
		end)
	end)
end

return M
