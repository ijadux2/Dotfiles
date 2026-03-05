-- by defaults tangle does not make derectories

local M = {}

local handlers = {}

local function get_buf_parser(bufnr, filetype)
	local parser_name = handlers[filetype] and handlers[filetype].parser or filetype
	if not parser_name then
		return nil
	end
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr, parser_name)
	if not ok then
		return nil
	end
	return parser
end

local function ensure_dir(filepath)
	local dir = vim.fn.fnamemodify(filepath, ":p:h")
	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, "p")
	end
end

local function files_equal(content, filepath)
	local fd = vim.loop.fs_open(filepath, "r", 0)
	if not fd then
		return false
	end

	local stat = vim.loop.fs_fstat(fd)
	if not stat or stat.size == 0 then
		vim.loop.fs_close(fd)
		return false
	end

	local buf = vim.loop.fs_read(fd, stat.size, 0)
	vim.loop.fs_close(fd)

	return buf == content
end

local function write_file(filepath, content)
	ensure_dir(filepath)

	if files_equal(content, filepath) then
		return false, "unchanged"
	end

	local fd = vim.loop.fs_open(filepath, "w", 438)
	if not fd then
		return true, "failed to open"
	end

	local ok, err = vim.loop.fs_write(fd, content, 0)
	vim.loop.fs_close(fd)

	if not ok then
		return true, err or "write failed"
	end
	return false, "written"
end

local function find_fenced_blocks_regex(bufnr)
	local blocks = {}
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	local in_fence = false
	local fence_lang = ""
	local fence_info = ""
	local fence_code = {}
	local fence_start_row = 0

	for i, line in ipairs(lines) do
		if not in_fence then
			local fence_match, rest = line:match("^%s*```(%w*)(.*)")
			if fence_match ~= nil then
				in_fence = true
				fence_lang = fence_match or ""
				fence_info = rest or ""
				fence_code = {}
				fence_start_row = i - 1
			end
		else
			if line:match("^%s*```%s*$") then
				in_fence = false
				local code = table.concat(fence_code, "\n")
				local tangle_file = handlers.markdown.tangle_marker(fence_lang .. " " .. fence_info)
				if tangle_file and code ~= "" then
					table.insert(blocks, {
						file = tangle_file,
						code = code,
						row = fence_start_row,
					})
				end
				fence_lang = ""
				fence_info = ""
				fence_code = {}
			else
				table.insert(fence_code, line)
			end
		end
	end

	return blocks
end

handlers.markdown = {
	parser = "markdown",
	tangle_marker = function(info)
		local tangle_match = info:match("tangle%s*=%s*[\"'](.-)[\"']") or info:match("tangle:%s*(%S+)")
		return tangle_match
	end,
	get_code = function(node, bufnr)
		local start_row, start_col, end_row, end_col = node:range()
		local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
		if #lines == 0 then
			return ""
		end

		if start_col > 0 then
			lines[1] = lines[1]:sub(start_col + 1)
		end
		if end_col > 0 and #lines > 0 then
			lines[#lines] = lines[#lines]:sub(1, end_col)
		end

		local content = table.concat(lines, "\n")
		return content:gsub("\n?```%s*$", "")
	end,
	find_blocks = function(parser, bufnr)
		if not parser then
			return find_fenced_blocks_regex(bufnr)
		end

		local tree = parser:parse()[1]
		local root = tree:root()
		local blocks = {}

		local function walk(node)
			if node:type() == "fenced_code_block" then
				local info_node, code_node
				for child in node:iter_children() do
					local ct = child:type()
					if ct == "info_string" then
						info_node = child
					elseif ct == "code_fence_content" then
						code_node = child
					end
				end

				local info = ""
				if info_node then
					local s, _, e, _ = info_node:range()
					local lines = vim.api.nvim_buf_get_lines(bufnr, s, e + 1, false)
					info = table.concat(lines, " ")
				end

				local tangle_file = handlers.markdown.tangle_marker(info)
				if code_node and tangle_file then
					local code = handlers.markdown.get_code(code_node, bufnr)
					local start_row = node:range()
					table.insert(blocks, { file = tangle_file, code = code, row = start_row })
				end
			end
			for child in node:iter_children() do
				walk(child)
			end
		end

		walk(root)
		return blocks
	end,
}

handlers.yaml = {
	parser = "yaml",
	tangle_marker = function(info)
		local key = info or ""
		local tangle_match = key:match("|([^|]+)$") or key:match("tangle%s*=%s*(%S+)") or key:match("tangle:%s*(%S+)")
		return tangle_match
	end,
	get_code = function(node, bufnr)
		local start_row, start_col, end_row, end_col = node:range()
		local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
		if #lines == 0 then
			return ""
		end

		if start_col > 0 then
			lines[1] = lines[1]:sub(start_col + 1)
		end

		local first_line = lines[1]
		first_line = first_line:gsub("^%s*[|>]%s*", "")
		lines[1] = first_line

		local indent = nil
		for i = 1, #lines do
			local line_indent = lines[i]:match("^%s+")
			if line_indent and #line_indent > 0 then
				if not indent or #line_indent < #indent then
					indent = line_indent
				end
			end
		end

		if indent and #indent > 0 then
			for i = 2, #lines do
				if lines[i]:sub(1, #indent) == indent then
					lines[i] = lines[i]:sub(#indent + 1)
				end
			end
		end

		return table.concat(lines, "\n")
	end,
	find_blocks = function(parser, bufnr)
		local blocks = {}

		if parser then
			local tree = parser:parse()[1]
			local root = tree:root()

			local function walk(node)
				if node:type() == "block_mapping_pair" then
					local children = {}
					for child in node:iter_children() do
						table.insert(children, child)
					end

					local key_node = children[1]
					local value_node = children[3]

					local key = ""
					if key_node then
						local s, _, e, _ = key_node:range()
						local lines = vim.api.nvim_buf_get_lines(bufnr, s, e + 1, false)
						key = table.concat(lines, ""):gsub(":%s*$", "")
					end

					local tangle_file = handlers.yaml.tangle_marker(key)

					local scalar_node
					if value_node and value_node:type() == "block_node" then
						for child in value_node:iter_children() do
							if child:type() == "block_scalar" then
								scalar_node = child
								break
							end
						end
					end

					if scalar_node and tangle_file then
						local code = handlers.yaml.get_code(scalar_node, bufnr)
						local start_row = scalar_node:range()
						table.insert(blocks, { file = tangle_file, code = code, row = start_row })
					end
				end
				for child in node:iter_children() do
					walk(child)
				end
			end

			walk(root)
		end

		local fenced_blocks = find_fenced_blocks_regex(bufnr)
		for _, block in ipairs(fenced_blocks) do
			table.insert(blocks, block)
		end

		table.sort(blocks, function(a, b)
			return a.row < b.row
		end)

		return blocks
	end,
}

local function find_conf_blocks(bufnr)
	local blocks = {}
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	local in_block = false
	local block_file = ""
	local block_lines = {}
	local block_start = 0

	for i, line in ipairs(lines) do
		local start_marker = line:match("^%s*#%s*%<%<%<%s*(%S+)")
		local end_marker = line:match("^%s*#%s*%>%>%>%s*")

		if start_marker then
			in_block = true
			block_file = start_marker
			block_lines = {}
			block_start = i - 1
		elseif end_marker and in_block then
			if block_file ~= "" and #block_lines > 0 then
				table.insert(blocks, {
					file = block_file,
					code = table.concat(block_lines, "\n"),
					row = block_start,
				})
			end
			in_block = false
			block_file = ""
			block_lines = {}
		elseif in_block then
			table.insert(block_lines, line)
		end
	end

	return blocks
end

local function find_conf_blocks_with_markdown(bufnr)
	local blocks = find_conf_blocks(bufnr)

	local fenced_blocks = find_fenced_blocks_regex(bufnr)
	for _, block in ipairs(fenced_blocks) do
		table.insert(blocks, block)
	end

	table.sort(blocks, function(a, b)
		return a.row < b.row
	end)

	return blocks
end

handlers.conf = {
	parser = nil,
	find_blocks = find_conf_blocks_with_markdown,
}

handlers.hyprlang = {
	parser = nil,
	find_blocks = find_conf_blocks_with_markdown,
}

local function get_handler(bufnr)
	local ft = vim.bo[bufnr].filetype
	return handlers[ft]
end

local function setup_virtual_text(blocks, bufnr)
	local ns = vim.api.nvim_create_namespace("tangle")

	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	for _, block in ipairs(blocks) do
		local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, ns, { block.row, 0 }, { block.row, -1 }, {})
		if #extmarks == 0 then
			vim.api.nvim_buf_set_extmark(bufnr, ns, block.row, 0, {
				virt_text = { { " -> " .. block.file, "Comment" } },
				virt_text_pos = "eol",
			})
		end
	end
end

function M.tangle()
	local bufnr = vim.api.nvim_get_current_buf()
	local handler = get_handler(bufnr)

	if not handler then
		return
	end

	local blocks
	if handler.parser then
		local parser = get_buf_parser(bufnr, vim.bo[bufnr].filetype)
		if not parser then
			vim.notify(
				"[tangle] Parser not available for " .. vim.bo[bufnr].filetype .. ", using regex fallback",
				vim.log.levels.INFO
			)
			blocks = find_fenced_blocks_regex(bufnr)
		else
			blocks = handler.find_blocks(parser, bufnr)
		end
	else
		blocks = handler.find_blocks(bufnr)
	end

	if #blocks == 0 then
		vim.notify("[tangle] No blocks with tangle metadata found", vim.log.levels.INFO)
		return
	end

	setup_virtual_text(blocks, bufnr)

	local outputs = {}
	for _, block in ipairs(blocks) do
		if not outputs[block.file] then
			outputs[block.file] = {}
		end
		table.insert(outputs[block.file], block.code)
	end

	local written = 0
	local skipped = 0
	local errors = {}

	for filepath, codes in pairs(outputs) do
		local content = table.concat(codes, "\n\n")
		local err, status = write_file(filepath, content)

		if status == "written" then
			written = written + 1
		elseif status == "unchanged" then
			skipped = skipped + 1
		else
			table.insert(errors, filepath .. ": " .. status)
		end
	end

	if #errors > 0 then
		vim.notify("[tangle] Errors: " .. table.concat(errors, ", "), vim.log.levels.ERROR)
	else
		vim.notify(string.format("[tangle] Written %d, skipped %d files", written, skipped), vim.log.levels.INFO)
	end
end

function M.setup()
	vim.api.nvim_create_user_command("Tangle", function()
		M.tangle()
	end, { desc = "Tangle code blocks from supported files" })

	vim.api.nvim_create_autocmd({ "BufWritePost" }, {
		pattern = { "*.md", "*.yml", "*.yaml", "*.conf" },
		callback = function(args)
			if vim.b[args.buf].auto_tangle then
				M.tangle()
			end
		end,
	})
end

return M
