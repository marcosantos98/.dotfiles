#!/usr/bin/env bash
file=/tmp/cpu-graph.txt
stat_file=/tmp/cpu-stat.txt
cores_stat_file=/tmp/cpu-cores-stat.txt
cores_graph_dir=/tmp/cpu-cores-graphs

# initialize if missing
[[ -f $file ]] || echo "" > "$file"
mkdir -p "$cores_graph_dir"

# Get CPU usage percentage (average)
if [[ -f $stat_file ]]; then
    prev_stats=$(cat "$stat_file")
    prev_idle=$(echo "$prev_stats" | cut -d' ' -f1)
    prev_total=$(echo "$prev_stats" | cut -d' ' -f2)
else
    prev_idle=0
    prev_total=0
fi

# Read current CPU stats
current=$(awk '/^cpu / {idle=$5+$6; total=idle+$2+$3+$4+$7+$8+$9; print idle " " total}' /proc/stat)
current_idle=$(echo "$current" | cut -d' ' -f1)
current_total=$(echo "$current" | cut -d' ' -f2)

# Save current stats for next run
echo "$current" > "$stat_file"

# Calculate usage percentage
if [[ $prev_total -gt 0 ]]; then
    diff_idle=$((current_idle - prev_idle))
    diff_total=$((current_total - prev_total))
    diff_used=$((diff_total - diff_idle))
    usage=$((diff_used * 100 / diff_total))
else
    usage=0
fi

# Generate graph bar based on CPU usage
level=$((usage / 12))  # Scale 0-100% to 0-8
((level>8)) && level=8
chars=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
bar="${chars[$level]}"

# append and keep last 30 bars
echo -n "$bar" >> "$file"
graph=$(tail -c 30 "$file")

# Build main text
text=$(printf " %02d%% %s" "$usage" "$graph")

# Calculate per-core CPU usage for tooltip
num_cores=$(grep -c "^cpu[0-9]" /proc/stat)

# Read previous core stats
if [[ -f $cores_stat_file ]]; then
    prev_cores=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && prev_cores+=("$line")
    done < "$cores_stat_file"
else
    prev_cores=()
fi

current_cores=()
tooltip_lines=()

# Process each core
for ((i=0; i<num_cores; i++)); do
    core_line=$(grep "^cpu${i} " /proc/stat)
    if [[ -n "$core_line" ]]; then
        core_idle=$(echo "$core_line" | awk '{print $5+$6}')
        core_total=$(echo "$core_line" | awk '{idle=$5+$6; total=idle+$2+$3+$4+$7+$8+$9; print total}')
        current_cores+=("$core_idle $core_total")
        
        # Get previous stats for this core
        if [[ ${#prev_cores[@]} -gt $i ]]; then
            prev_line="${prev_cores[$i]}"
            prev_core_idle=$(echo "$prev_line" | cut -d' ' -f1)
            prev_core_total=$(echo "$prev_line" | cut -d' ' -f2)
            
            if [[ -n "$prev_core_idle" && -n "$prev_core_total" && $prev_core_total -gt 0 ]]; then
                diff_core_idle=$((core_idle - prev_core_idle))
                diff_core_total=$((core_total - prev_core_total))
                diff_core_used=$((diff_core_total - diff_core_idle))
                core_usage=$((diff_core_used * 100 / diff_core_total))
            else
                core_usage=0
            fi
        else
            core_usage=0
        fi
        
        # Generate graph for this core
        core_graph_file="$cores_graph_dir/core${i}.txt"
        [[ -f "$core_graph_file" ]] || echo "" > "$core_graph_file"
        
        core_level=$((core_usage / 12))
        ((core_level>8)) && core_level=8
        core_bar="${chars[$core_level]}"
        
        echo -n "$core_bar" >> "$core_graph_file"
        core_graph=$(tail -c 30 "$core_graph_file")
        
        # Build tooltip lines
        tooltip_lines+=("Core $i: $(printf "%02d%%" "$core_usage") $core_graph")
    fi
done

# Save current cores stats for next run
printf '%s\n' "${current_cores[@]}" > "$cores_stat_file"

# Build tooltip text
tooltip=$(printf '%s\n' "${tooltip_lines[@]}")

# Output JSON - waybar needs JSON for multi-line tooltips
if command -v python3 &> /dev/null; then
    python3 -c "import json, sys; print(json.dumps({'text': sys.argv[1], 'tooltip': sys.argv[2]}, ensure_ascii=False))" "$text" "$tooltip"
else
    # Fallback: manual JSON escaping
    tooltip_escaped=$(echo "$tooltip" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    printf '{"text":"%s","tooltip":"%s"}\n' "$text" "$tooltip_escaped"
fi
