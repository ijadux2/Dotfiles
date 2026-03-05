local M = {}

M.browser_buf = nil
M.history = {}
M.history_index = 0

local function create_buffer()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].filetype = "w3m"
	vim.bo[buf].bufhidden = "hide"
	return buf
end

local function set_options(buf)
	vim.bo[buf].modifiable = true
	vim.bo[buf].readonly = false
end

local function goto_url(url)
	if not M.browser_buf or not vim.api.nvim_buf_is_valid(M.browser_buf) then
		M.browser_buf = create_buffer()
	end

	local win = vim.api.nvim_get_current_win()
	vim.cmd("vsplit")
	local new_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(new_win, M.browser_buf)
	vim.api.nvim_set_current_win(win)
	vim.api.nvim_win_close(new_win, true)

	vim.api.nvim_win_set_buf(0, M.browser_buf)
	set_options(M.browser_buf)

	local output = vim.fn.system("w3m -dump " .. vim.fn.shellescape(url))
	vim.api.nvim_buf_set_lines(M.browser_buf, 0, -1, false, vim.split(output, "\n", { trimempty = true }))

	vim.bo[M.browser_buf].modifiable = false
	vim.bo[M.browser_buf].readonly = true

	vim.b[M.browser_buf].w3m_url = url
	vim.b[M.browser_buf].w3m_title = url

	vim.cmd("setlocal readonly")
	vim.cmd("setlocal nomodifiable")

	table.insert(M.history, url)
	M.history_index = #M.history
end

function M.browse(url)
	if not url or url == "" then
		vim.ui.input({ prompt = "Enter URL: " }, function(input)
			if input and input ~= "" then
				if not input:match("^https?://") then
					input = "https://" .. input
				end
				goto_url(input)
			end
		end)
	else
		goto_url(url)
	end
end

function M.back()
	if M.history_index > 1 then
		M.history_index = M.history_index - 1
		goto_url(M.history[M.history_index])
	end
end

function M.forward()
	if M.history_index < #M.history then
		M.history_index = M.history_index + 1
		goto_url(M.history[M.history_index])
	end
end

function M.reload()
	local url = vim.b.w3m_url
	if url then
		goto_url(url)
	end
end

function M.home()
	goto_url("https://duckduckgo.com")
end

return M
