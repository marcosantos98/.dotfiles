#!/bin/sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT=/tmp/obs-waybar-output.json
STATE=/tmp/obs-waybar-mic.state
SCENES=/tmp/obs-waybar-scenes.list
CURRENT=/tmp/obs-waybar-current.scene

if ! pgrep -x obs >/dev/null 2>&1; then
	rm -f "$OUTPUT" "$STATE" "$SCENES" "$CURRENT" /tmp/obs-waybar-scenes.hash
	printf '{"text":""}\n'
	exit 0
fi

python3 "$SCRIPT_DIR/obs_ws.py" sync-scenes 2>/dev/null

current=$(cat "$CURRENT" 2>/dev/null)
[ -z "$current" ] && current="OBS"

mic_on=false
if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q 'Mute: yes'; then
	:
elif pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -q 'yes'; then
	:
else
	mic_on=true
fi

if [ "$mic_on" = true ]; then
	class=live
	mic_tip="Mic on"
else
	class=off
	mic_tip="Mic muted"
fi

tooltip="$mic_tip"
if [ -f "$SCENES" ]; then
	while IFS= read -r scene; do
		[ -z "$scene" ] && continue
		if [ "$scene" = "$current" ]; then
			tooltip="$tooltip
● $scene"
		else
			tooltip="$tooltip
  $scene"
		fi
	done < "$SCENES"
fi

text="${current} ●"
state_key="${class}:${current}:${mic_tip}"

if [ -f "$OUTPUT" ] && [ -f "$STATE" ] && [ "$(cat "$STATE")" = "$state_key" ]; then
	cat "$OUTPUT"
	exit 0
fi

printf '%s' "$state_key" > "$STATE"
python3 -c "import json,sys; print(json.dumps({'text':sys.argv[1],'class':sys.argv[2],'tooltip':sys.argv[3]}))" \
	"$text" "$class" "$tooltip" | tee "$OUTPUT"
