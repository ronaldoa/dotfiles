#!/usr/bin/env bash
# Polybar weather module (OpenWeatherMap).
#   weather.sh           -> short text for the bar: "<icon> 18°"
#   weather.sh --detail  -> desktop notification with details
# API key is read from ~/.config/openweathermap/key (kept out of the repo) or $OWM_KEY.

CITY="Boston"
UNITS="metric"
LANG_CODE="zh_cn"
ICON_COLOR="#EBCB8B"

API="https://api.openweathermap.org/data/2.5"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/polybar-weather.json"
KEY="${OWM_KEY:-$(cat "$HOME/.config/openweathermap/key" 2>/dev/null)}"

# OpenWeatherMap icon code -> nf-weather glyph (Hack Nerd Font)
get_icon() {
    case $1 in
        01d) printf '';; 01n) printf '';;
        02d) printf '';; 02n) printf '';;
        03*) printf '';; 04*) printf '';;
        09*) printf '';;
        10d) printf '';; 10n) printf '';;
        11d) printf '';; 11n) printf '';;
        13d) printf '';; 13n) printf '';;
        50d) printf '';; 50n) printf '';;
        *)   printf '';;
    esac
}

fetch() {
    [ -n "$KEY" ] || return 1
    local q="appid=$KEY&q=$CITY&units=$UNITS&lang=$LANG_CODE"
    local current forecast
    current=$(curl -sf --max-time 10 "$API/weather?$q") || return 1
    forecast=$(curl -sf --max-time 10 "$API/forecast?$q&cnt=8") || return 1
    mkdir -p "$(dirname "$CACHE")"
    jq -n --argjson c "$current" --argjson f "$forecast" '{current: $c, forecast: $f}' > "$CACHE.tmp" \
        && mv "$CACHE.tmp" "$CACHE"
}

if [ "$1" = "--detail" ]; then
    [ -s "$CACHE" ] || fetch || { notify-send "天气" "获取天气失败"; exit 1; }
    body=$(jq -r '
        def t: . | round | tostring + "°";
        def hm: strflocaltime("%H:%M");
        .current as $c | .forecast.list as $l |
        "\($c.weather[0].description)  \($c.main.temp | t)(体感 \($c.main.feels_like | t))\n" +
        "24 小时: \([$l[].main.temp_min] | min | t) ~ \([$l[].main.temp_max] | max | t)\n" +
        "湿度 \($c.main.humidity)%   风速 \($c.wind.speed) m/s\n" +
        "日出 \($c.sys.sunrise | hm)   日落 \($c.sys.sunset | hm)\n\n" +
        ([$l[0:4][] | "\(.dt | hm)  \(.main.temp | t)  \(.weather[0].description)"] | join("\n"))
    ' "$CACHE")
    notify-send -i weather-few-clouds "$CITY 天气" "$body"
    exit 0
fi

fetch
# On network failure keep showing the last known value; print nothing if there is none.
[ -s "$CACHE" ] || { echo ""; exit 0; }
icon=$(get_icon "$(jq -r '.current.weather[0].icon' "$CACHE")")
temp=$(jq -r '.current.main.temp | round' "$CACHE")
echo "%{F$ICON_COLOR}$icon%{F-} $temp°"
