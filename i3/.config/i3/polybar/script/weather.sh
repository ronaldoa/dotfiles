#!/usr/bin/env bash
# Polybar weather module (OpenWeatherMap).
#   weather.sh           -> short text for the bar: "<icon> 18°"
#   weather.sh --detail  -> toggle the weather card (current, details, next 24 h)
# API key is read from ~/.config/openweathermap/key (kept out of the repo) or $OWM_KEY.
# Location comes from ~/.config/i3/bin/location (by IP).

UNITS="metric"
LANG_CODE="zh_cn"
ICON_COLOR="#EBCB8B"

API="https://api.openweathermap.org/data/2.5"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/polybar-weather.json"
KEY="${OWM_KEY:-$(cat "$HOME/.config/openweathermap/key" 2>/dev/null)}"

# OpenWeatherMap icon code -> nf-weather glyph (Hack Nerd Font)
get_icon() {
    case $1 in
        01d) printf '';; 01n) printf '';;
        02d) printf '';; 02n) printf '';;
        03*) printf '';; 04*) printf '';;
        09*) printf '';;
        10d) printf '';; 10n) printf '';;
        11d) printf '';; 11n) printf '';;
        13d) printf '';; 13n) printf '';;
        50d) printf '';; 50n) printf '';;
        *)   printf '';;
    esac
}

fetch() {
    [ -n "$KEY" ] || return 1
    local lat lon
    read -r lat lon < <(~/.config/i3/bin/location)
    local q="appid=$KEY&lat=$lat&lon=$lon&units=$UNITS&lang=$LANG_CODE"
    local current forecast
    current=$(curl -sf --max-time 10 "$API/weather?$q") || return 1
    forecast=$(curl -sf --max-time 10 "$API/forecast?$q&cnt=8") || return 1
    mkdir -p "$(dirname "$CACHE")"
    jq -n --argjson c "$current" --argjson f "$forecast" '{current: $c, forecast: $f}' > "$CACHE.tmp" \
        && mv "$CACHE.tmp" "$CACHE"
}

if [ "$1" = "--detail" ]; then
    # Toggle the weather card (conky, drawn by ~/.config/conky/weather-popup.lua)
    conf="$HOME/.config/conky/weather-popup.conf"
    pkill -f "conky -d -c $conf" && exit 0
    [ -s "$CACHE" ] || fetch || { notify-send "天气" "获取天气失败"; exit 1; }
    read -r x y < <(~/.config/i3/bin/popup-pos 402)
    conky -d -c "$conf" -x "$x" -y "$y" >/dev/null 2>&1
    # conky puts its override window at the bottom of the stack; bring the popup above all windows
    exec ~/.config/i3/bin/xstack weather-popup above
fi

fetch
# On network failure keep showing the last known value; print nothing if there is none.
[ -s "$CACHE" ] || { echo ""; exit 0; }
icon=$(get_icon "$(jq -r '.current.weather[0].icon' "$CACHE")")
temp=$(jq -r '.current.main.temp | round' "$CACHE")
echo "%{F$ICON_COLOR}$icon%{F-} $temp°"
