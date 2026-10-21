#!/usr/bin/env bash
# Polybar audio spectrum (tail script): prints a row of ▁▂▃▄▅▆▇█ bars per frame from cava.
# Prints blanks of the same width while it is silent, so the bar slot (and the centre island) keeps its size.

bars="▁▂▃▄▅▆▇█"
count=14
work=$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/polybar-cava.XXXXXX") || exit 1
conf="$work/config"
cava_pid= filter_pid=
cleanup() {
    [ -z "$cava_pid" ] || kill "$cava_pid" 2>/dev/null
    [ -z "$filter_pid" ] || kill "$filter_pid" 2>/dev/null
    rm -f "$conf" "$work/frames"
    rmdir "$work"
}
trap cleanup EXIT
trap 'exit 0' HUP INT TERM

cat > "$conf" <<CONF
[general]
bars = $count
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

# cava prints "3;5;0;...;" per frame: all-zero frames become $count spaces, map 0-7 to bar glyphs, drop the separators
dict="/^\\(0;\\)*\$/s/.*/$(printf '%*s' "$count" '')/;s/;//g;"
for i in {0..7}; do
    dict+="s/$i/${bars:$i:1}/g;"
done

mkfifo "$work/frames"
cava -p "$conf" >"$work/frames" &
cava_pid=$!
sed -u "$dict" <"$work/frames" &
filter_pid=$!
wait "$filter_pid"
