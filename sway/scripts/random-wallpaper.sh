#!/bin/bash

# Random wallpaper setter for Hyprland startup with swww - Catppuccin Mocha theme
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

# Ensure swww daemon is running
if ! pgrep -x "swww-daemon" > /dev/null; then
    swww-daemon &
    sleep 1
fi

# Get a random wallpaper
RANDOM_WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | shuf -n 1)

# Set the wallpaper
if [ -n "$RANDOM_WALLPAPER" ]; then
    swww img "$RANDOM_WALLPAPER" --transition-type fade --transition-fps 60
    echo "$RANDOM_WALLPAPER" > "$HOME/.current_wallpaper"
    
    # Send notification with just the filename
    WALLPAPER_NAME=$(basename "$RANDOM_WALLPAPER")
    notify-send "󰸉 Random wallpaper" "Set to: $WALLPAPER_NAME"
fi