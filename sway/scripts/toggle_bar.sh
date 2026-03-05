#!/bin/bash

# Mango status bar toggle script
# This script toggles waybar on/off

if pgrep -x "waybar" > /dev/null; then
    killall waybar
    notify-send "󰍯 Status bar" "Hidden"
else
    waybar &
    notify-send "󰍯 Status bar" "Shown"
fi