#!/bin/bash

# Workspace navigation with fuzzel - shows workspaces and applications
# Uses Catppuccin Mocha theme with green accent

get_workspace_info() {
    local workspace_list=""
    
    # Get all workspaces and their clients
    if command -v hyprctl >/dev/null 2>&1; then
        # Get workspace IDs
        workspace_ids=$(hyprctl workspaces -j | jq -r '.[].id' | sort -n)
        
        for workspace_id in $workspace_ids; do
            # Get clients for this workspace
            clients=$(hyprctl clients -j | jq -r --arg wid "$workspace_id" '.[] | select(.workspace.id == ($wid|tonumber)) | "\(.class)"' | sort | uniq -c | sort -nr)
            
            if [ -n "$clients" ]; then
                # Format: "1. kitty(x2), thunar, yazi"
                formatted_clients=$(echo "$clients" | awk '{print $2 "(" $1 "x)"}' | tr '\n' ', ' | sed 's/,$//')
                workspace_list="${workspace_list}${workspace_id}. ${formatted_clients}\n"
            else
                workspace_list="${workspace_list}${workspace_id}. (empty)\n"
            fi
        done
    fi
    
    echo -e "$workspace_list"
}

# Show workspace selector
selected_workspace=$(get_workspace_info | fuzzel --prompt="Workspace: " \
    --font="JetBrains Mono:size=12" \
    --background-color=1e1e2eff \
    --text-color=cdd6f4ff \
    --selection-color=a6e3a1ff \
    --selection-text-color=1e1e2eff \
    --border-color=a6e3a1ff \
    --border-radius=8 \
    --border-width=2 \
    --lines=10 \
    --width=60 \
    --anchor=center \
    --dmenu)

# Switch to selected workspace
if [ -n "$selected_workspace" ]; then
    workspace_number=$(echo "$selected_workspace" | cut -d'.' -f1)
    if [ -n "$workspace_number" ] && [[ "$workspace_number" =~ ^[0-9]+$ ]]; then
        hyprctl dispatch workspace "$workspace_number"
    fi
fi