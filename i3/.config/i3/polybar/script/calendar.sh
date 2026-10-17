#!/usr/bin/env bash
# Toggle the calendar card under the polybar clock (conky, drawn by ~/.config/conky/calendar-popup.lua).
conf="$HOME/.config/conky/calendar-popup.conf"
pkill -f "conky -d -c $conf" && exit 0
read -r x y < <(~/.config/i3/bin/popup-pos 448)
conky -d -c "$conf" -x "$x" -y "$y" >/dev/null 2>&1
# conky puts its override window at the bottom of the stack; bring the popup above all windows
exec ~/.config/i3/bin/xstack calendar-popup above
