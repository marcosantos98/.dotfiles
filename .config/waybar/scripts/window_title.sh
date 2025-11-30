#!/bin/sh

# Function to get and display window title
get_window_title() {
    N_WINDOWS=$(hyprctl activeworkspace -j | jq '.windows')
    
    if [ "$N_WINDOWS" -eq 0 ]; then
        echo "u doing? get to code bruh"
        return
    fi
    
    # Get active window address first
    ACTIVE_ADDRESS=$(hyprctl activewindow -j | jq -r '.address')
    
    # Get focused window title from clients using the active window address
    WINDOW_TITLE=$(hyprctl clients -j | jq -r --arg addr "$ACTIVE_ADDRESS" '.[] | select(.address == $addr) | .title')
    
    if [ -z "$WINDOW_TITLE" ]; then
        # Fallback to activewindow if clients doesn't work
        WINDOW_TITLE=$(hyprctl activewindow -j | jq -r '.title')
    fi
    
    echo "$WINDOW_TITLE"
}

# Output initial window title
get_window_title

# Handle IPC events
handle() {
    case $1 in
        activewindow*|openwindow*|closewindow*)
            get_window_title
            ;;
    esac
}

# Listen to Hyprland IPC socket
socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do 
    handle "$line"
done
