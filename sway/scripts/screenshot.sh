#!/bin/bash

# Screenshot utility using fuzzel with Catppuccin Mocha
actions="Full Screen\nActive Window\nSelection\nCopy to Clipboard"

# Get timestamp for filename
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
SAVE_DIR="$HOME/Pictures/Screenshots"

# Create screenshots directory if it doesn't exist
mkdir -p "$SAVE_DIR"

selected=$(echo -e "$actions" | fuzzel --prompt="Screenshot: " \
    --font="JetBrains Mono:size=10" \
    --background-color=1e1e2eff \
    --text-color=cdd6f4ff \
    --selection-color=89b4faff \
    --selection-text-color=1e1e2eff \
    --border-color=89b4faff \
    --border-radius=8 \
    --border-width=2 \
    --lines=4 \
    --width=50 \
    --anchor=center \
    --dmenu)

case "$selected" in
    "Full Screen")
        grim "$SAVE_DIR/screenshot_$TIMESTAMP.png"
        notify-send "Screenshot" "Full screen screenshot saved to $SAVE_DIR"
        ;;
    "Active Window")
        grim -g "$(hyprctl activewindow -j | jq -r '.at | "\(.[0]),\(.[1]) \(.[2]x\(.[3])"')" "$SAVE_DIR/screenshot_$TIMESTAMP.png"
        notify-send "Screenshot" "Active window screenshot saved to $SAVE_DIR"
        ;;
    "Selection")
        grim -g "$(slurp)" "$SAVE_DIR/screenshot_$TIMESTAMP.png"
        notify-send "Screenshot" "Selection screenshot saved to $SAVE_DIR"
        ;;
    "Copy to Clipboard")
        grim -g "$(slurp)" - | wl-copy
        notify-send "Screenshot" "Selection copied to clipboard"
        ;;
esac