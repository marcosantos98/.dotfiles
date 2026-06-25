#!/bin/sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCENES=/tmp/obs-waybar-scenes.list
CURRENT=/tmp/obs-waybar-current.scene

python3 "$SCRIPT_DIR/obs_ws.py" sync-scenes 2>/dev/null

current=$(cat "$CURRENT" 2>/dev/null)
menu="Toggle microphone"

if [ -f "$SCENES" ]; then
	while IFS= read -r scene; do
		[ -z "$scene" ] && continue
		if [ "$scene" = "$current" ]; then
			menu="$menu
● $scene"
		else
			menu="$menu
$scene"
		fi
	done < "$SCENES"
fi

choice=$(printf '%s\n' "$menu" | wofi --dmenu --prompt "OBS" --width 320 --lines 12)
[ -z "$choice" ] && exit 0

case "$choice" in
"Toggle microphone")
	wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
	;;
*)
	scene="${choice#● }"
	python3 "$SCRIPT_DIR/obs_ws.py" switch "$scene" 2>/dev/null || {
		command -v notify-send >/dev/null && notify-send "OBS" "Could not switch scene"
	}
	;;
esac

rm -f /tmp/obs-waybar-output.json /tmp/obs-waybar-mic.state
