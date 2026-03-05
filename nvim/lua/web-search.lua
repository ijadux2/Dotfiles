local M = {}

local search_engines = {
	{
		name = "DuckDuckGo",
		icon = "🔍",
		url = "https://duckduckgo.com/?q=",
		desc = "Default search engine",
	},
	{
		name = "URL",
		icon = "🌐",
		url = "",
		desc = "enter custom URL",
		custom = true,
	},
	{
		name = "Wikipedia",
		icon = "📚",
		url = "https://en.wikipedia.org/wiki/Special:Search?search=",
		desc = "Wikipedia encyclopedia",
	},
	{
		name = "YouTube",
		icon = "▶️",
		url = "https://www.youtube.com/results?search_query=",
		desc = "YouTube videos",
	},
	{
		name = "GitHub",
		icon = "󰤤",
		url = "https://github.com/search?q=",
		desc = "GitHub code search",
	},
	{
		name = "Stack Overflow",
		icon = "󰌆",
		url = "https://stackoverflow.com/search?q=",
		desc = "Stack Overflow questions",
	},
	{
		name = "Reddit",
		icon = "󰑔",
		url = "https://www.reddit.com/search/?q=",
		desc = "Reddit search",
	},
	{
		name = "Web (DuckDuckGo)",
		icon = "🌍",
		url = "https://html.duckduckgo.com/html/?q=",
		desc = "Web search (minimal)",
	},
	{
		name = "Browse in Neovim (w3m)",
		icon = "󰀯",
		url = "https://duckduckgo.com/?q=",
		desc = "Open in neovim terminal browser",
		nvim = true,
	},
}

local function open_url(url)
	vim.fn.jobstart({ "xdg-open", url })
end

local function open_in_browser(url)
	require("text-browser").browse(url)
end

local function url_encode(str)
	if str then
		str = str:gsub("\n", "\r\n")
		str = str:gsub("([^%w %-%_%.%~])", function(c)
			return string.format("%%%02X", string.byte(c))
		end)
		str = str:gsub(" ", "%%20")
	end
	return str
end

local function build_search_url(query, engine)
	return engine.url .. url_encode(query)
end

function M.search()
	vim.ui.input({ prompt = "Search: " }, function(query)
		if not query or query == "" then
			return
		end

		local items = {}
		for _, engine in ipairs(search_engines) do
			table.insert(items, {
				text = engine.name,
				engine = engine,
				query = query,
			})
		end

		require("snacks").picker({
			title = "🔍 Search: " .. query,
			items = items,
			format = function(item, _)
				return {
					{ item.engine.icon, "SnacksPickerIcon" },
					{ " " },
					{ item.text, "SnacksPickerTitle" },
					{ " │ " .. item.engine.desc, "SnacksPickerComment" },
				}
			end,
			layout = {
				preset = "default",
			},
			confirm = function(self, item)
				if item and item.engine then
					if item.engine.custom then
						vim.ui.input({ prompt = "Enter URL: " }, function(url)
							if url and url ~= "" then
								open_url(url)
							end
						end)
					else
						local url = build_search_url(item.query, item.engine)
						if item.engine.nvim then
							open_in_browser(url)
						else
							open_url(url)
						end
					end
					self:close()
				end
			end,
		})
	end)
end

return M
