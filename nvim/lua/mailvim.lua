local M = {}

local uv = vim.loop

-- --------------------------
-- Async runner
-- --------------------------
local function run_async(cmd, args, callback)
	local stdout = uv.new_pipe(false)
	local handle

	handle = uv.spawn(cmd, {
		args = args,
		stdio = { nil, stdout, nil },
	}, function()
		stdout:close()
		handle:close()
	end)

	local output = {}
	stdout:read_start(function(err, data)
		assert(not err, err)
		if data then
			table.insert(output, data)
		else
			callback(table.concat(output))
		end
	end)
end

-- --------------------------
-- Sync Mail
-- --------------------------
function M.sync()
	run_async("mbsync", { "-a" }, function()
		run_async("notmuch", { "new" }, function()
			vim.notify("Mail synced.")
		end)
	end)
end

-- --------------------------
-- Search Mail
-- --------------------------
function M.search(query)
	if not query or query == "" then
		return
	end

	run_async("notmuch", { "search", "--format=text", query }, function(result)
		local lines = vim.split(result, "\n", { trimempty = true })
		M.open_picker(lines)
	end)
end

-- --------------------------
-- Open Snacks Picker
-- --------------------------
function M.open_picker(lines)
	local snacks = require("snacks")

	local items = {}

	for _, line in ipairs(lines) do
		table.insert(items, {
			text = line,
			value = line,
		})
	end

	snacks.picker({
		title = "Mail Search",
		items = items,

		confirm = function(picker, selected)
			picker:close()
			M.open_thread(selected.value)
		end,
	})
end

-- --------------------------
-- Open Thread
-- --------------------------
function M.open_thread(line)
	local thread_id = line:match("thread:([^%s]+)")
	if not thread_id then
		return
	end

	run_async("notmuch", {
		"show",
		"--format=text",
		thread_id,
	}, function(content)
		M.floating_preview(content)
	end)
end

-- --------------------------
-- Floating Preview Window
-- --------------------------
function M.floating_preview(content)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))

	vim.bo[buf].filetype = "mail"

	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)

	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = (vim.o.lines - height) / 2,
		col = (vim.o.columns - width) / 2,
		border = "rounded",
	})
end

-- --------------------------
-- Compose Mail
-- --------------------------
function M.compose()
	local buf = vim.api.nvim_create_buf(false, true)

	local template = {
		"To: ",
		"Subject: ",
		"",
		"---",
		"",
	}

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, template)
	vim.bo[buf].filetype = "markdown"

	local width = math.floor(vim.o.columns * 0.7)
	local height = math.floor(vim.o.lines * 0.7)

	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = (vim.o.lines - height) / 2,
		col = (vim.o.columns - width) / 2,
		border = "rounded",
	})

	vim.keymap.set("n", "<leader>ms", function()
		M.send(buf)
	end, { buffer = buf })
end

-- --------------------------
-- Send Mail
-- --------------------------
function M.send(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	local to = lines[1]:gsub("^To:%s*", "")
	local subject = lines[2]:gsub("^Subject:%s*", "")

	local body = table.concat(vim.list_slice(lines, 4), "\n")

	local msg = string.format("To: %s\nSubject: %s\n\n%s", to, subject, body)

	local tmp = os.tmpname()
	local f = io.open(tmp, "w")
	f:write(msg)
	f:close()

	run_async("msmtp", { to }, function()
		os.remove(tmp)
		vim.notify("Mail sent.")
	end)
end

-- --------------------------
-- Commands
-- --------------------------
vim.api.nvim_create_user_command("MailSync", M.sync, {})
vim.api.nvim_create_user_command("MailSearch", function(opts)
	M.search(opts.args)
end, { nargs = 1 })

vim.api.nvim_create_user_command("MailCompose", M.compose, {})

return M
