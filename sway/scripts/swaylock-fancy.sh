#!/bin/bash

# Enhanced swaylock script with wallpaper and Catppuccin Mocha theme
# Similar to hyprlock aesthetic

WALLPAPER="$HOME/Downloads/sakura-aura.jpg"
CONFIG="$HOME/.config/sway/swaylock.conf"

# Check if wallpaper exists
if [ -f "$WALLPAPER" ]; then
    swaylock \
        --config "$CONFIG" \
        --image "$WALLPAPER" \
        --scaling fill \
        --clock \
        --indicator \
        --indicator-radius 150 \
        --indicator-thickness 7 \
        --font-size 24 \
        --datestr "%a, %B %d, %Y" \
        --timestr "%H:%M:%S" \
        --ignore-empty-password \
        --show-failed-attempts \
        --indicator-idle-visible
else
    # Fallback to config-only if wallpaper not found
    swaylock --config "$CONFIG"
fi