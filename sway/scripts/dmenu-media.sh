#!/bin/bash

# Media controls using fuzzel with Catppuccin Mocha
actions="Play/Pause\nNext\nPrevious\nStop\nVolume Up\nVolume Down\nMute"

selected=$(echo -e "$actions" | fuzzel --prompt="Media: " \
    --font="JetBrains Mono:size=10" \
    --background-color=1e1e2eff \
    --text-color=cdd6f4ff \
    --selection-color=a6e3a1ff \
    --selection-text-color=1e1e2eff \
    --border-color=a6e3a1ff \
    --border-radius=8 \
    --border-width=2 \
    --lines=7 \
    --width=50 \
    --anchor=center \
    --dmenu)

case "$selected" in
    "Play/Pause") 
        if command -v playerctl >/dev/null 2>&1; then
            playerctl play-pause
        else
            notify-send "Error" "playerctl not found"
        fi
        ;;
    "Next") 
        if command -v playerctl >/dev/null 2>&1; then
            playerctl next
        else
            notify-send "Error" "playerctl not found"
        fi
        ;;
    "Previous") 
        if command -v playerctl >/dev/null 2>&1; then
            playerctl previous
        else
            notify-send "Error" "playerctl not found"
        fi
        ;;
    "Stop") 
        if command -v playerctl >/dev/null 2>&1; then
            playerctl stop
        else
            notify-send "Error" "playerctl not found"
        fi
        ;;
    "Volume Up") pactl set-sink-volume @DEFAULT_SINK@ +5% ;;
    "Volume Down") pactl set-sink-volume @DEFAULT_SINK@ -5% ;;
    "Mute") pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
esac