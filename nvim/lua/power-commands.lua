local M = {}

local function run_cmd(cmd)
	vim.fn.jobstart({ "sh", "-c", cmd })
end

local function playerctl(cmd)
	run_cmd("playerctl " .. cmd .. " 2>/dev/null")
end

local function brightness(action)
	local step = "5%"
	if action == "up" then
		run_cmd("brightnessctl s +" .. step .. " 2>/dev/null")
	elseif action == "down" then
		run_cmd("brightnessctl s " .. step .. "- 2>/dev/null")
	end
end

local function volume(action)
	if action == "up" then
		run_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ 2>/dev/null")
	elseif action == "down" then
		run_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- 2>/dev/null")
	elseif action == "mute" then
		run_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle 2>/dev/null")
	end
end

local commands = {
	{
		category = "Power",
		icon = "󰐥",
		items = {
			{
				name = "Shutdown",
				icon = "󰐥",
				action = function()
					run_cmd("systemctl poweroff")
				end,
			},
			{
				name = "Reboot",
				icon = "󰒉",
				action = function()
					run_cmd("systemctl reboot")
				end,
			},
			{
				name = "Sleep",
				icon = "󰒋",
				action = function()
					run_cmd("systemctl suspend")
				end,
			},
			{
				name = "Hibernate",
				icon = "󰌾",
				action = function()
					run_cmd("systemctl hibernate")
				end,
			},
			{
				name = "Lock Screen",
				icon = "󰌾",
				action = function()
					run_cmd("hyprlock")
				end,
			},
			{
				name = "Logout",
				icon = "󰗼",
				action = function()
					run_cmd("loginctl terminate-session $XDG_SESSION_ID")
				end,
			},
		},
	},
	{
		category = "Media",
		icon = "󰝚",
		items = {
			{
				name = "Play/Pause",
				icon = "󰐌",
				action = function()
					playerctl("play-pause")
				end,
			},
			{
				name = "Next Track",
				icon = "󰒭",
				action = function()
					playerctl("next")
				end,
			},
			{
				name = "Previous Track",
				icon = "󰒮",
				action = function()
					playerctl("previous")
				end,
			},
			{
				name = "Stop",
				icon = "󰓛",
				action = function()
					playerctl("stop")
				end,
			},
			{
				name = "Volume Up",
				icon = "󰝝",
				action = function()
					volume("up")
				end,
			},
			{
				name = "Volume Down",
				icon = "󰝞",
				action = function()
					volume("down")
				end,
			},
			{
				name = "Mute/Unmute",
				icon = "󰝤",
				action = function()
					volume("mute")
				end,
			},
		},
	},
	{
		category = "Brightness",
		icon = "󰛨",
		items = {
			{
				name = "Brightness Up",
				icon = "󰛨",
				action = function()
					brightness("up")
				end,
			},
			{
				name = "Brightness Down",
				icon = "󰛩",
				action = function()
					brightness("down")
				end,
			},
		},
	},
	{
		category = "Screenshot",
		icon = "󰕧",
		items = {
			{
				name = "Full Screen",
				icon = "󰕧",
				action = function()
					run_cmd(
						"maim -s ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png && notify-send 'Screenshot saved'"
					)
				end,
			},
			{
				name = "Selection",
				icon = "󰕧",
				action = function()
					run_cmd(
						"maim -s $(xdg-user-dir PICTURES)/screenshot-$(date +%Y%m%d-%H%M%S).png && notify-send 'Screenshot saved'"
					)
				end,
			},
			{
				name = "Copy to Clipboard",
				icon = "󰆴",
				action = function()
					run_cmd("maim -s | xclip -selection clipboard -t image/png && notify-send 'Screenshot copied'")
				end,
			},
		},
	},
	{
		category = "System",
		icon = "󰒓",
		items = {
			{
				name = "Toggle WiFi",
				icon = "󰤨",
				action = function()
					run_cmd("nmcli radio wifi toggle")
				end,
			},
			{
				name = "Toggle Bluetooth",
				icon = "󰂯",
				action = function()
					run_cmd("rfkill toggle bluetooth")
				end,
			},
			{
				name = "Night Light",
				icon = "󰺿",
				action = function()
					run_cmd("redshift -x; redshift -O 4500k 2>/dev/null || echo 'redshift not installed'")
				end,
			},
			{
				name = "Reset Night Light",
				icon = "󰛨",
				action = function()
					run_cmd("redshift -x 2>/dev/null")
				end,
			},
			{
				name = "Kill Wayland",
				icon = "󰒉",
				action = function()
					run_cmd("pkill -9 wayland; pkill -9 weston")
				end,
			},
		},
	},
}

function M.pick()
	local items = {}

	for _, cat in ipairs(commands) do
		table.insert(items, {
			text = cat.category,
			category = true,
			icon = cat.icon,
		})
		for _, item in ipairs(cat.items) do
			table.insert(items, {
				text = item.name,
				cmd = item,
				icon = item.icon .. " ",
			})
		end
	end

	require("snacks").picker({
		title = "�.Power Commands",
		items = items,
		format = function(item, _)
			if item.category then
				return {
					{ item.icon, "SnacksPickerIcon" },
					{ " " },
					{ item.text, "SnacksPickerTitle" },
				}
			end
			return {
				{ item.icon, "SnacksPickerIcon" },
				{ " " },
				{ item.text, "SnacksPickerTitle" },
			}
		end,
		layout = { preset = "default" },
		confirm = function(self, item)
			if item and item.cmd and item.cmd.action then
				item.cmd.action()
				self:close()
			end
		end,
	})
end

function M.media(action)
	if action then
		if action == "play-pause" then
			playerctl("play-pause")
		elseif action == "next" then
			playerctl("next")
		elseif action == "prev" then
			playerctl("previous")
		elseif action == "stop" then
			playerctl("stop")
		elseif action == "volume-up" then
			volume("up")
		elseif action == "volume-down" then
			volume("down")
		elseif action == "mute" then
			volume("mute")
		elseif action == "brightness-up" then
			brightness("up")
		elseif action == "brightness-down" then
			brightness("down")
		end
		return
	end

	local items = {}
	for _, item in ipairs(commands[2].items) do
		table.insert(items, { text = item.name, cmd = item, icon = item.icon .. " " })
	end

	require("snacks").picker({
		title = "󰝚 Media Controls",
		items = items,
		format = function(item, _)
			return { { item.icon, "SnacksPickerIcon" }, { " " }, { item.text, "SnacksPickerTitle" } }
		end,
		layout = { preset = "ivy" },
		confirm = function(self, item)
			if item and item.cmd and item.cmd.action then
				item.cmd.action()
				self:close()
			end
		end,
	})
end

function M.brightness_pick()
	local items = {}
	for _, item in ipairs(commands[3].items) do
		table.insert(items, { text = item.name, cmd = item, icon = item.icon .. " " })
	end

	require("snacks").picker({
		title = "󰛨 Brightness",
		items = items,
		format = function(item, _)
			return { { item.icon, "SnacksPickerIcon" }, { " " }, { item.text, "SnacksPickerTitle" } }
		end,
		layout = { preset = "ivy" },
		confirm = function(self, item)
			if item and item.cmd and item.cmd.action then
				item.cmd.action()
				self:close()
			end
		end,
	})
end

return M
