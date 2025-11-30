#!/usr/bin/env bash
cores_stat_file=/tmp/cpu-cores-stat.txt
cores_graph_dir=/tmp/cpu-cores-graphs

# Get number of cores
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
chars=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)

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
        
        tooltip_lines+=("Core $i: $(printf "%02d%%" "$core_usage") $core_graph")
    fi
done

# Save current cores stats for next run
printf '%s\n' "${current_cores[@]}" > "$cores_stat_file"

# Output tooltip
printf '%s\n' "${tooltip_lines[@]}"

