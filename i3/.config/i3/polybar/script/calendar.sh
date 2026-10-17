#!/usr/bin/env bash
# Toggle the calendar card under the polybar clock (conky, drawn by ~/.config/conky/calendar-popup.lua).
conf="$HOME/.config/conky/calendar-popup.conf"
pkill -f "conky -d -c $conf" && exit 0
conky -d -c "$conf" >/dev/null 2>&1
# conky puts its override window at the bottom of the stack; bring the popup above all windows
exec ~/.config/i3/bin/xstack calendar-popup above
