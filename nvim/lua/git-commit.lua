local M = {}

local function get_branches(callback)
	vim.system({ "git", "branch" }, { text = true }, function(obj)
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
				local name = trimmed:gsub("^%*%s*", "")
				table.insert(branches, { name = name })
			end
		end

		vim.schedule(function()
			callback(branches)
		end)
	end)
end

local function get_status(callback)
	vim.system({ "git", "status", "--porcelain" }, { text = true }, function(obj)
		vim.schedule(function()
			callback(obj.stdout)
		end)
	end)
end

local function commit_to_branch(branch, message, callback)
	vim.system({ "git", "checkout", branch }, { text = true }, function(checkout_obj)
		if checkout_obj.code ~= 0 then
			vim.schedule(function()
				callback(false, "Failed to checkout: " .. checkout_obj.stderr)
			end)
			return
		end

		vim.system({ "git", "add", "-A" }, { text = true }, function(add_obj)
			if add_obj.code ~= 0 then
				vim.schedule(function()
					callback(false, "Failed to stage: " .. add_obj.stderr)
				end)
				return
			end

			vim.system({ "git", "commit", "-m", message }, { text = true }, function(commit_obj)
				vim.schedule(function()
					if commit_obj.code == 0 then
						callback(true, "Committed to: " .. branch)
					else
						callback(false, "Failed to commit: " .. commit_obj.stderr)
					end
				end)
			end)
		end)
	end)
end

function M.commit()
	get_branches(function(branches)
		if type(branches) == "string" then
			vim.notify(branches, vim.log.levels.ERROR)
			return
		end

		get_status(function(status)
			if status == "" then
				vim.notify("No changes to commit", vim.log.levels.WARN)
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
				title = "Commit to Branch",
				items = items,
				format = function(item, _)
					return {
						{ "󰜤", "SnacksPickerIcon" },
						{ " " },
						{ item.text, "SnacksPickerTitle" },
					}
				end,
				layout = { preset = "default" },
				confirm = function(self, item)
					if item and item.branch then
						self:close()
						vim.ui.input({ prompt = "Commit message: " }, function(msg)
							if not msg or msg == "" then
								return
							end
							commit_to_branch(item.branch.name, msg, function(success, output)
								if success then
									vim.notify(output, vim.log.levels.INFO)
								else
									vim.notify(output, vim.log.levels.ERROR)
								end
							end)
						end)
					end
				end,
			})
		end)
	end)
end

return M
