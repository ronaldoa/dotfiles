#!/usr/bin/env bash
# Polybar audio spectrum (tail script): prints a row of ▁▂▃▄▅▆▇█ bars per frame from cava.
# Prints an empty line while nothing is playing, so the module disappears.

bars="▁▂▃▄▅▆▇█"
conf="${XDG_RUNTIME_DIR:-/tmp}/polybar-cava.conf"

cat > "$conf" <<CONF
[general]
bars = 14
framerate = 30
[input]
method = pulse
source = auto
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
CONF

# cava prints "3;5;0;...;" per frame: blank all-zero frames, map 0-7 to bar glyphs, drop the separators
dict='/^\(0;\)*$/s/.*//;s/;//g;'
for i in {0..7}; do
    dict+="s/$i/${bars:$i:1}/g;"
done

pkill -f -- "cava -p $conf"
exec cava -p "$conf" | sed -u "$dict"
