#!/bin/bash

# ====================================================================
# Kitty Clean Directory Launcher with Fuzzel
# Shows only titles; paths are managed internally.
# ====================================================================

# --- CONFIGURATION (Aesthetics Unchanged) ---
BG_COLOR="1e1e2eff"
TEXT_COLOR="cdd6f4ff"
SELECTION_COLOR="f38ba8ff"
BORDER_COLOR="cba6f7ff"

FUZZEL_FONT="JetBrainsMonoNL Nerd Font:size=11"
FUZZEL_BORDER_RADIUS=8
FUZZEL_BORDER_WIDTH=2
FUZZEL_WIDTH=50
FUZZEL_LINES=10

# --- DIRECTORY MAP (Internal Data Structure) ---
# Define an associative array to map clean labels to actual paths
declare -A DIRECTORY_MAP=(
  ["Home Directory"]="$HOME"
  ["Projects"]="$HOME/codespace//"
  ["Config Files"]="$HOME/.config"
  ["Scripts"]="$HOME/.config/sway/scripts/"
  ["Neovim"]="$HOME/.config/nvim/"
  ["sway"]="$HOME/.config/sway/"
  ["Kitty"]="$HOME/.config/kitty/"
  ["gitstack"]="$HOME/codespace/gitstack/"
  ["gitstack-app"]="$HOME/codespace/gitstack-app/"
  ["velentine"]="$HOME/codespace/web-page/"
  ["zig"]="$HOME/codespace/zig/"
  ["lua-dev"]="$HOME/codespace/lua-project/appdev/"
)

# --- MENU ACTIONS (Clean Labels Only) ---
# Create a newline-separated string of just the keys (labels)
ACTIONS=$(printf "%s\n" "${!DIRECTORY_MAP[@]}")

# --- CORE FUNCTION ---

# Function to launch Kitty in the specified directory
launch_kitty_directory() {
  local target_dir="$1"

  # Resolve the home directory alias (~) to the absolute path
  target_dir=$(echo "$target_dir" | sed "s|~|$HOME|g")

  # Check if the directory exists and is a directory
  if [[ ! -d "$target_dir" ]]; then
    command -v notify-send &>/dev/null && notify-send "Kitty Launch Error" "Directory not found: $target_dir"
    echo "Error: Directory not found: $target_dir" >&2
    exit 1
  fi

  # Launch Kitty directly into the resolved directory
  kitty --directory "$target_dir" -e nvim &
}

# --- MAIN EXECUTION ---

# 1. Run Fuzzel menu
# The input to fuzzel is now only the clean labels from $ACTIONS
selected_label=$(echo -e "$ACTIONS" | fuzzel \
  --prompt="Open Directory: " \
  --font="$FUZZEL_FONT" \
  --background-color="$BG_COLOR" \
  --text-color="$TEXT_COLOR" \
  --selection-color="$SELECTION_COLOR" \
  --selection-text-color="$BG_COLOR" \
  --border-color="$BORDER_COLOR" \
  --border-radius="$FUZZEL_BORDER_RADIUS" \
  --border-width="$FUZZEL_BORDER_WIDTH" \
  --lines="$FUZZEL_LINES" \
  --width="$FUZZEL_WIDTH" \
  --anchor=center \
  --dmenu)

# Exit if no selection was made
if [[ -z "$selected_label" ]]; then
  exit 0
fi

# 2. Look up the hidden path using the selected label
directory_path="${DIRECTORY_MAP[$selected_label]}"

# Check if the lookup was successful (the label must be a valid key)
if [[ -z "$directory_path" ]]; then
  command -v notify-send &>/dev/null && notify-send "Logic Error" "Invalid menu choice selected: $selected_label"
  echo "Error: Invalid menu choice selected: $selected_label" >&2
  exit 1
fi

# 3. Launch Kitty
launch_kitty_directory "$directory_path"
