-- Weather popup card (click the weather in polybar to toggle): current conditions, details
-- and the next 24 hours in 3-hour steps, in the same style as the desktop widgets.
-- Data comes from the polybar weather cache (~/.cache/polybar-weather.json).

local L = dofile(os.getenv('HOME') .. '/.config/conky/lib.lua')
local text, card, rgba = L.text, L.card, L.rgba
local FONT, FONT_LIGHT, FONT_BOLD, ICONS = L.FONT, L.FONT_LIGHT, L.FONT_BOLD, L.ICONS
local TEXT, DIM, BLUE, YELLOW = L.TEXT, L.DIM, L.BLUE, L.YELLOW

local W, H, PAD = 400, 290, 20

-- First line: current conditions; then one line per 3-hour forecast step
local QUERY = [[jq -r '
    def hm: strflocaltime("%H:%M");
    (.current as $c | .forecast.list as $l |
        [$c.name, $c.weather[0].main, $c.weather[0].icon, ($c.main.temp | round), ($c.main.feels_like | round),
         $c.main.humidity, $c.wind.speed, ($c.sys.sunrise | hm), ($c.sys.sunset | hm),
         ([$l[].main.temp_min] | min | round), ([$l[].main.temp_max] | max | round), ($c.dt | hm)] | @tsv),
    (.forecast.list[0:8][] | [(.dt | hm), .weather[0].icon, (.main.temp | round), ((.pop // 0) * 100 | round)] | @tsv)
' ~/.cache/polybar-weather.json]]

local function load()
    local lines = L.split(L.cached(QUERY, 60), '\n')
    local c = L.split(lines[1] or '', '\t')
    if #c < 12 then return nil end
    local data = {
        city = c[1], desc = c[2], icon = c[3], temp = c[4], feels = c[5], hum = c[6], wind = c[7],
        sunrise = c[8], sunset = c[9], low = c[10], high = c[11], updated = c[12], hours = {},
    }
    for i = 2, #lines do
        local f = L.split(lines[i], '\t')
        if #f == 4 then
            data.hours[#data.hours + 1] = {time = f[1], icon = f[2], temp = f[3], pop = L.num(f[4])}
        end
    end
    return data
end

function conky_weather_popup()
    local cr = L.begin(W + 2, H + 2)
    if not cr then return end
    local x, y = 1, 1
    card(x, y, W, H, 0.96)

    local d = load()
    if not d then
        text(x + PAD, y + 34, 'WEATHER', FONT_BOLD, 12, YELLOW)
        text(x + PAD, y + 80, 'No data yet', FONT, 16, DIM)
        L.finish()
        return
    end
    local right = x + W - PAD

    -- Header
    text(x + PAD, y + 34, d.city:upper(), FONT_BOLD, 12, YELLOW)
    text(right, y + 34, 'Updated ' .. d.updated, FONT, 10, DIM, 'right')

    -- Now: big icon + temperature, summary on the right
    text(x + PAD, y + 104, L.weather_icon(d.icon), ICONS, 48, YELLOW)
    text(x + PAD + 76, y + 106, d.temp .. '°', FONT_LIGHT, 60, TEXT)
    text(right, y + 66, d.desc, FONT_BOLD, 16, TEXT, 'right')
    text(right, y + 88, 'Feels like ' .. d.feels .. '°', FONT, 12, DIM, 'right')
    text(right, y + 106, 'H ' .. d.high .. '°   L ' .. d.low .. '°', FONT, 12, DIM, 'right')

    -- Details: four columns
    local details = {
        {'HUMIDITY', d.hum .. '%'},
        {'WIND', string.format('%.1f m/s', L.num(d.wind))},
        {'SUNRISE', d.sunrise},
        {'SUNSET', d.sunset},
    }
    local col = (W - 2 * PAD) / #details
    for i, item in ipairs(details) do
        local cx = x + PAD + (i - 1) * col
        text(cx, y + 142, item[1], FONT_BOLD, 9, DIM)
        text(cx, y + 162, item[2], FONT, 14, TEXT)
    end

    -- Divider
    rgba({1, 1, 1, 0.08})
    cairo_rectangle(cr, x + PAD, y + 180, W - 2 * PAD, 1)
    cairo_fill(cr)

    -- Next 24 hours
    local n = math.max(#d.hours, 1)
    local step = (W - 2 * PAD) / n
    for i, h in ipairs(d.hours) do
        local cx = x + PAD + (i - 0.5) * step
        text(cx, y + 204, i == 1 and 'Now' or h.time, FONT, 10, DIM, 'center')
        text(cx, y + 236, L.weather_icon(h.icon), ICONS, 20, YELLOW, 'center')
        text(cx, y + 262, h.temp .. '°', FONT, 14, TEXT, 'center')
        if h.pop >= 10 then
            text(cx, y + 279, h.pop .. '%', FONT, 9, BLUE, 'center')
        end
    end

    L.finish()
end
