#!/bin/bash

# Wallpaper selector using fuzzel for Hyprland with swww - Catppuccin Mocha theme
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

# Ensure swww daemon is running
if ! pgrep -x "swww-daemon" >/dev/null; then
  swww-daemon &
  sleep 1
fi

# Create a simple list of wallpapers with names
cd "$WALLPAPER_DIR" || exit 1

# Create fuzzel config
cat >/tmp/fuzzel-config <<'EOF'
# Catppuccin Mocha theme for fuzzel
font = "JetBrains Mono Nerd Font 12"
[colors]
background = 1e1e2eff
text = cdd6f4ff
match = 89b4faff
selection = 45475aff
selection-match = 89b4faff
selection-text = cdd6f4ff
border = 585b70ff
[border]
width = 2
radius = 8
EOF

# Select wallpaper using fuzzel with Catppuccin Mocha theme
SELECTED_NAME=$(ls *.jpg *.jpeg *.png 2>/dev/null | fuzzel --dmenu --prompt="󰸉 Select wallpaper: " --config=/tmp/fuzzel-config)

# Clean up
rm -f /tmp/fuzzel-config

# Exit if no selection made
if [ -z "$SELECTED_NAME" ]; then
  exit 0
fi

# Set the wallpaper using swww
SELECTED_PATH="$WALLPAPER_DIR/$SELECTED_NAME"
swww img "$SELECTED_PATH" --transition-type grow --transition-pos 0.5,0.5 --transition-step 90 --transition-fps 60

# Save the current wallpaper to a file for persistence
echo "$SELECTED_PATH" >"$HOME/.current_wallpaper"

# Send notification with just the filename
notify-send "󰸉 Wallpaper changed" "Set to: $SELECTED_NAME"
