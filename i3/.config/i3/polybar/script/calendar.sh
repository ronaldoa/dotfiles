#!/usr/bin/env bash
# Toggle a small floating calendar (last/this/next month) under the polybar clock.
# Any key inside the popup also closes it.
if pgrep -f 'alacritty --class cal-popup' >/dev/null; then
    pkill -f 'alacritty --class cal-popup'
    exit
fi

alacritty --class cal-popup \
    -o 'window.dimensions.columns=66' -o 'window.dimensions.lines=9' \
    -o 'window.padding.x=8' -o 'window.padding.y=6' \
    -e sh -c 'cal -3; read -rsn1' >/dev/null 2>&1 &

# Wait for the window, then pin it to the top-right corner just below the bar
for _ in $(seq 30); do
    i3-msg -t get_tree | grep -q '"class":"cal-popup"' && break
    sleep 0.1
done
read -r ox oy ow < <(i3-msg -t get_workspaces | python3 -c '
import json, sys
r = next(w["rect"] for w in json.load(sys.stdin) if w["focused"])
print(r["x"], r["y"], r["width"])')
i3-msg -q "[class=\"cal-popup\"] move position $((ox + ow - 820)) px $((oy + 6)) px"
