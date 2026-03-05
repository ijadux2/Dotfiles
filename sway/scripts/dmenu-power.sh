#!/bin/bash

# Power menu using fuzzel with Catppuccin Mocha
actions="Shutdown\nReboot\nLogout\nSuspend\nHibernate\nLock"

selected=$(echo -e "$actions" | fuzzel --prompt="Power: " \
  --font="JetBrains Mono:size=10" \
  --background-color=1e1e2eff \
  --text-color=cdd6f4ff \
  --selection-color=f38ba8ff \
  --selection-text-color=1e1e2eff \
  --border-color=f38ba8ff \
  --border-radius=8 \
  --border-width=2 \
  --lines=6 \
  --width=50 \
  --anchor=center \
  --dmenu)

case "$selected" in
"Shutdown") systemctl poweroff ;;
"Reboot") systemctl reboot ;;
"Logout") hyprctl dispatch exit ;;
"Suspend") systemctl suspend ;;
"Hibernate") systemctl hibernate ;;
"Lock") hyprlock ;;
esac
