local M = {}

local screenshot_dir = vim.fn.expand("~/Pictures/screenshot")

local function ensure_dir()
    vim.fn.system("mkdir -p " .. screenshot_dir)
end

local function get_timestamp()
    return os.date("%Y-%m-%d_%H-%M-%S")
end

local function notify(msg, level)
    vim.notify(msg, level or vim.log.levels.INFO, { title = "Screenshot" })
end

local function save_to_file(path)
    local output = vim.fn.system("grim '" .. vim.fn.fnameescape(path) .. "'")
    if vim.v.shell_error == 0 then
        notify("Saved: " .. path)
    else
        notify("Failed: " .. output, vim.log.levels.ERROR)
    end
end

function M.capture_window()
    ensure_dir()
    local filename = "window_" .. get_timestamp() .. ".png"
    local path = screenshot_dir .. "/" .. filename
    save_to_file(path)
end

function M.capture_selection()
    ensure_dir()
    local filename = "selection_" .. get_timestamp() .. ".png"
    local path = screenshot_dir .. "/" .. filename
    local output = vim.fn.system("grim -g \"$(slurp)\" '" .. vim.fn.fnameescape(path) .. "'")
    if vim.v.shell_error == 0 then
        notify("Saved: " .. path)
    else
        notify("Failed: " .. output, vim.log.levels.ERROR)
    end
end

function M.capture_fullscreen()
    ensure_dir()
    local filename = "fullscreen_" .. get_timestamp() .. ".png"
    local path = screenshot_dir .. "/" .. filename
    save_to_file(path)
end

function M.capture_window_clipboard()
    local output = vim.fn.system("grim -w - | wl-copy -t image/png")
    if vim.v.shell_error == 0 then
        notify("Copied to clipboard")
    else
        notify("Failed: " .. output, vim.log.levels.ERROR)
    end
end

function M.capture_selection_clipboard()
    local output = vim.fn.system("grim -g \"$(slurp)\" - | wl-copy -t image/png")
    if vim.v.shell_error == 0 then
        notify("Copied to clipboard")
    else
        notify("Failed: " .. output, vim.log.levels.ERROR)
    end
end

function M.capture_fullscreen_clipboard()
    local output = vim.fn.system("grim - | wl-copy -t image/png")
    if vim.v.shell_error == 0 then
        notify("Copied to clipboard")
    else
        notify("Failed: " .. output, vim.log.levels.ERROR)
    end
end

function M.pick()
    local items = {
        { text = "Window (Save to File)", action = M.capture_window },
        { text = "Selection (Save to File)", action = M.capture_selection },
        { text = "Fullscreen (Save to File)", action = M.capture_fullscreen },
        { text = "Window (Copy to Clipboard)", action = M.capture_window_clipboard },
        { text = "Selection (Copy to Clipboard)", action = M.capture_selection_clipboard },
        { text = "Fullscreen (Copy to Clipboard)", action = M.capture_fullscreen_clipboard },
    }

    require("snacks").picker({
        title = "📸 Screenshot",
        items = items,
        format = function(item, _)
            return {
                { "📷", "SnacksPickerIcon" },
                { " " },
                { item.text, "SnacksPickerTitle" },
            }
        end,
        layout = {
            preset = "ivy",
        },
        confirm = function(self, item)
            if item and item.action then
                item.action()
                self:close()
            end
        end,
    })
end

return M
