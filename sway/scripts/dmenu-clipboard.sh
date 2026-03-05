#!/bin/bash

# Clipboard manager using fuzzel with Catppuccin Mocha
cliphist list | fuzzel --prompt="Clipboard: " \
  --font="JetBrains Mono:size=10" \
  --background-color=1e1e2eff \
  --text-color=cdd6f4ff \
  --selection-color=cba6f7ff \
  --selection-text-color=1e1e2eff \
  --border-color=cba6f7ff \
  --border-radius=8 \
  --border-width=2 \
  --lines=15 \
  --width=50 \
  --anchor=center \
  --dmenu | cliphist decode | wl-copy
