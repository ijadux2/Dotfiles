#!/bin/bash

# Music Player with fuzzel - supports all formats including .webm and .mp4
# Uses Catppuccin Mocha theme with pink accent
# Directory: ~/music
# Built as fuzzel command

MUSIC_DIR="$HOME/music"
CURRENT_TRACK_FILE="/tmp/current_track.txt"
PLAY_MODE_FILE="/tmp/play_mode.txt"
FUZZEL_CONFIG="$HOME/.config/fuzzel/fuzzel.ini"

# Initialize files if they don't exist
[ ! -f "$PLAY_MODE_FILE" ] && echo "normal" > "$PLAY_MODE_FILE"

# Fuzzel theming function
get_fuzzel_args() {
    echo --font="JetBrains Mono:size=11" \
        --background-color=1e1e2eff \
        --text-color=cdd6f4ff \
        --selection-color=f9e2afff \
        --selection-text-color=1e1e2eff \
        --border-color=f9e2afff \
        --border-radius=8 \
        --border-width=2 \
        --anchor=center
}

# Function to get all music files with metadata
get_music_files() {
    find "$MUSIC_DIR" -type f \( \
        -iname "*.mp3" -o \
        -iname "*.flac" -o \
        -iname "*.wav" -o \
        -iname "*.ogg" -o \
        -iname "*.m4a" -o \
        -iname "*.opus" -o \
        -iname "*.webm" -o \
        -iname "*.mp4" -o \
        -iname "*.mkv" -o \
        -iname "*.avi" -o \
        -iname "*.mov" \
    \) 2>/dev/null | while read -r file; do
        # Get file info for better display
        local duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$file" 2>/dev/null | cut -d. -f1)
        local size=$(du -h "$file" | cut -f1)
        local basename_file=$(basename "$file")
        local dirname_file=$(basename "$(dirname "$file")")
        
        if [ -n "$duration" ] && [ "$duration" != "0" ]; then
            local minutes=$((duration / 60))
            local seconds=$((duration % 60))
            printf "%-30s │ %02d:%02d │ %s │ %s │ %s\n" \
                "${basename_file:0:30}" "$minutes" "$seconds" "$size" "$dirname_file" "$file"
        else
            printf "%-30s │ --:-- │ %s │ %s │ %s\n" \
                "${basename_file:0:30}" "$size" "$dirname_file" "$file"
        fi
    done | sort
}

# Function to format track list for fuzzel
format_track_list() {
    get_music_files | while IFS=' │ ' read -r name duration size dir path; do
        printf "🎵 %-30s │ %s │ %s\n" "$name" "$duration" "$dir"
    done
}

# Function to play a track
play_track() {
    local track="$1"
    if [ -n "$track" ]; then
        # Kill any existing player processes
        pkill -f "mpv\|vlc\|ffplay" 2>/dev/null
        
        # Play with mpv (supports all formats)
        mpv --no-terminal --really-quiet "$track" &
        echo "$track" > "$CURRENT_TRACK_FILE"
        
        # Show notification
        track_name=$(basename "$track")
        notify-send "Now Playing" "$track_name" -i audio-x-generic
    fi
}

# Function to show playback controls
show_controls() {
    local current_track=""
    if [ -f "$CURRENT_TRACK_FILE" ]; then
        current_track=$(cat "$CURRENT_TRACK_FILE")
        track_name=$(basename "$current_track")
        current_info="Now: $track_name"
    else
        current_info="No track playing"
    fi
    
    local play_mode="normal"
    if [ -f "$PLAY_MODE_FILE" ]; then
        play_mode=$(cat "$PLAY_MODE_FILE")
    fi

    actions="▶️ Play/Pause
⏹️ Stop
⏭️ Next
⏮️ Previous
🔁 Repeat: $play_mode
🔀 Shuffle
📜 Playlist
🎵 Select Track
🔊 Volume Up
🔉 Volume Down
🔇 Mute
ℹ️ Now Playing"
    
    local fuzzel_args=$(get_fuzzel_args)
    selected=$(echo -e "$actions" | fuzzel $fuzzel_args \
        --prompt="$current_info | Control: " \
        --lines=12 \
        --width=60 \
        --dmenu)

    case "$selected" in
        "▶️ Play/Pause") 
            if pgrep -f "mpv" > /dev/null; then
                playerctl play-pause 2>/dev/null || echo "pause" > /tmp/mpv_command
            else
                if [ -n "$current_track" ]; then
                    play_track "$current_track"
                fi
            fi
            ;;
        "⏹️ Stop") 
            pkill -f "mpv\|vlc\|ffplay"
            rm -f "$CURRENT_TRACK_FILE"
            notify-send "Music Player" "Stopped"
            ;;
        "⏭️ Next")
            get_next_track && play_track "$next_track"
            ;;
        "⏮️ Previous")
            get_prev_track && play_track "$prev_track"
            ;;
        "🔁 Repeat: $play_mode")
            toggle_repeat_mode
            ;;
        "🔀 Shuffle")
            play_random_track
            ;;
        "📜 Playlist")
            show_playlist
            ;;
        "🎵 Select Track")
            select_and_play_track
            ;;
        "🔊 Volume Up") 
            if command -v playerctl >/dev/null 2>&1; then
                playerctl volume 0.1+
            else
                pactl set-sink-volume @DEFAULT_SINK@ +5%
            fi
            ;;
        "🔉 Volume Down") 
            if command -v playerctl >/dev/null 2>&1; then
                playerctl volume 0.1-
            else
                pactl set-sink-volume @DEFAULT_SINK@ -5%
            fi
            ;;
        "🔇 Mute") 
            pactl set-sink-mute @DEFAULT_SINK@ toggle
            ;;
        "ℹ️ Now Playing")
            if [ -n "$current_track" ]; then
                notify-send "Now Playing" "$track_name\n$(basename "$(dirname "$current_track")")"
            else
                notify-send "Music Player" "No track playing"
            fi
            ;;
    esac
}

# Function to select and play a track
select_and_play_track() {
    local music_files=$(get_music_files)
    if [ -z "$music_files" ]; then
        notify-send "Music Player" "No music files found in $MUSIC_DIR"
        return
    fi
    
    local formatted_list=$(format_track_list)
    
    local fuzzel_args=$(get_fuzzel_args)
    selected=$(echo -e "$formatted_list" | fuzzel $fuzzel_args \
        --prompt="🎵 Select Track: " \
        --lines=20 \
        --width=80 \
        --dmenu)
    
    if [ -n "$selected" ]; then
        # Extract the track name and find full path
        local track_name=$(echo "$selected" | sed 's/🎵 //' | cut -d'│' -f1 | xargs)
        local full_path=$(get_music_files | grep -F "$track_name" | cut -d'│' -f4 | head -1)
        play_track "$full_path"
    fi
}

# Function to get next track
get_next_track() {
    local current_track=""
    if [ -f "$CURRENT_TRACK_FILE" ]; then
        current_track=$(cat "$CURRENT_TRACK_FILE")
    fi
    
    local music_files=$(get_music_files)
    local next_track=$(echo "$music_files" | grep -A1 -F "$current_track" | tail -1)
    
    if [ -z "$next_track" ] || [ "$next_track" = "$current_track" ]; then
        # If we're at the end, check repeat mode
        local play_mode=$(cat "$PLAY_MODE_FILE")
        if [ "$play_mode" = "repeat" ]; then
            next_track=$(echo "$music_files" | head -1)
        else
            notify-send "Music Player" "End of playlist"
            return 1
        fi
    fi
    
    echo "$next_track" > /tmp/next_track
    return 0
}

# Function to get previous track
get_prev_track() {
    local current_track=""
    if [ -f "$CURRENT_TRACK_FILE" ]; then
        current_track=$(cat "$CURRENT_TRACK_FILE")
    fi
    
    local music_files=$(get_music_files)
    local prev_track=$(echo "$music_files" | grep -B1 -F "$current_track" | head -1)
    
    if [ -z "$prev_track" ] || [ "$prev_track" = "$current_track" ]; then
        # If we're at the beginning, go to last track
        prev_track=$(echo "$music_files" | tail -1)
    fi
    
    echo "$prev_track" > /tmp/prev_track
    return 0
}

# Function to play random track
play_random_track() {
    local music_files=$(get_music_files)
    local count=$(echo "$music_files" | wc -l)
    if [ $count -gt 0 ]; then
        local random_line=$((RANDOM % count + 1))
        local random_track=$(echo "$music_files" | sed -n "${random_line}p")
        play_track "$random_track"
    fi
}

# Function to toggle repeat mode
toggle_repeat_mode() {
    local current_mode=$(cat "$PLAY_MODE_FILE")
    local new_mode="normal"
    
    case "$current_mode" in
        "normal") new_mode="repeat" ;;
        "repeat") new_mode="repeat_one" ;;
        "repeat_one") new_mode="normal" ;;
    esac
    
    echo "$new_mode" > "$PLAY_MODE_FILE"
    notify-send "Repeat Mode" "$new_mode"
}

# Function to show playlist
show_playlist() {
    local music_files=$(get_music_files)
    local current_track=""
    if [ -f "$CURRENT_TRACK_FILE" ]; then
        current_track=$(cat "$CURRENT_TRACK_FILE")
    fi
    
    local formatted_list=$(get_music_files | while IFS=' │ ' read -r name duration size dir path; do
        if [ "$path" = "$current_track" ]; then
            printf "▶️ %-30s │ %s │ %s\n" "$name" "$duration" "$dir"
        else
            printf "   %-30s │ %s │ %s\n" "$name" "$duration" "$dir"
        fi
    done)
    
    local fuzzel_args=$(get_fuzzel_args)
    selected=$(echo -e "$formatted_list\n---\n🎵 Add New Track\n🗑️ Clear Playlist" | fuzzel $fuzzel_args \
        --prompt="📜 Playlist: " \
        --lines=20 \
        --width=80 \
        --dmenu)
    
    if [ -n "$selected" ]; then
        if [[ "$selected" == "🎵 Add New Track" ]]; then
            select_and_play_track
        elif [[ "$selected" == "🗑️ Clear Playlist" ]]; then
            pkill -f "mpv\|vlc\|ffplay"
            rm -f "$CURRENT_TRACK_FILE"
            notify-send "Playlist" "Cleared"
        elif [[ "$selected" == ▶️* ]] || [[ "$selected" =~ ^[[:space:]]* ]]; then
            # Extract track name from selected line and play
            local track_name=$(echo "$selected" | sed 's/[▶️ ]//' | cut -d'│' -f1 | xargs)
            local full_path=$(get_music_files | grep -F "$track_name" | cut -d'│' -f4 | head -1)
            play_track "$full_path"
        fi
    fi
}

# Function to show main menu
show_main_menu() {
    local current_track=""
    if [ -f "$CURRENT_TRACK_FILE" ]; then
        current_track=$(cat "$CURRENT_TRACK_FILE")
        track_name=$(basename "$current_track")
        local prompt="🎵 Music Player | Now: $track_name"
    else
        local prompt="🎵 Music Player"
    fi

    actions="🎵 Select Track
🎛️ Controls
📜 Playlist
🔀 Random Track
⏹️ Stop All
📂 Refresh Library
ℹ️ Track Info"
    
    local fuzzel_args=$(get_fuzzel_args)
    selected=$(echo -e "$actions" | fuzzel $fuzzel_args \
        --prompt="$prompt" \
        --lines=7 \
        --width=50 \
        --dmenu)
    
    case "$selected" in
        "🎵 Select Track") select_and_play_track ;;
        "🎛️ Controls") show_controls ;;
        "📜 Playlist") show_playlist ;;
        "🔀 Random Track") play_random_track ;;
        "⏹️ Stop All") 
            pkill -f "mpv\|vlc\|ffplay"
            rm -f "$CURRENT_TRACK_FILE"
            notify-send "Music Player" "All playback stopped"
            ;;
        "📂 Refresh Library")
            rm -f /tmp/music_cache_*
            notify-send "Music Player" "Library refreshed"
            show_main_menu
            ;;
        "ℹ️ Track Info")
            if [ -f "$CURRENT_TRACK_FILE" ]; then
                current_track=$(cat "$CURRENT_TRACK_FILE")
                track_name=$(basename "$current_track")
                dir_name=$(basename "$(dirname "$current_track")")
                file_size=$(du -h "$current_track" | cut -f1)
                duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$current_track" 2>/dev/null | cut -d. -f1)
                if [ -n "$duration" ] && [ "$duration" != "0" ]; then
                    minutes=$((duration / 60))
                    seconds=$((duration % 60))
                    notify-send "Track Info" "🎵 $track_name\n📁 $dir_name\n⏱️  ${minutes}:${seconds}\n💾 $file_size"
                else
                    notify-send "Track Info" "🎵 $track_name\n📁 $dir_name\n💾 $file_size"
                fi
            else
                notify-send "Track Info" "No track playing"
            fi
            ;;
    esac
}

# Check if music directory exists
if [ ! -d "$MUSIC_DIR" ]; then
    notify-send "Music Player Error" "Music directory $MUSIC_DIR not found"
    exit 1
fi

# Function to create fuzzel launcher entry
create_fuzzel_launcher() {
    local launcher_dir="$HOME/.local/share/applications"
    mkdir -p "$launcher_dir"
    
    cat > "$launcher_dir/fuzzel-music.desktop" <<EOF
[Desktop Entry]
Name=Music Player
Comment=Launch fuzzel music player
Exec=$0 --select
Icon=audio-x-generic
Terminal=false
Type=Application
Categories=AudioVideo;Audio;
EOF
    
    notify-send "Music Player" "Fuzzel launcher created! Restart fuzzel to see it."
}

# Parse arguments
case "${1:-}" in
    "--controls") show_controls ;;
    "--playlist") show_playlist ;;
    "--random") play_random_track ;;
    "--select") select_and_play_track ;;
    "--create-launcher") create_fuzzel_launcher ;;
    "--help") 
        echo "Usage: $0 [OPTION]"
        echo "Options:"
        echo "  (no args)          Show main menu"
        echo "  --controls         Show playback controls"
        echo "  --playlist         Show playlist"
        echo "  --random           Play random track"
        echo "  --select           Select and play track"
        echo "  --create-launcher  Create fuzzel launcher entry"
        echo "  --help             Show this help"
        echo ""
        echo "Built for fuzzel with Catppuccin Mocha theming"
        echo "Supports: MP3, FLAC, WAV, OGG, M4A, Opus, WebM, MP4, MKV, AVI, MOV"
        ;;
    *) show_main_menu ;;
esac