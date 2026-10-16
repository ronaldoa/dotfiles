-- Apple-style desktop widgets drawn with Cairo: rounded translucent cards in a 2x2 grid
-- (clock, weather, system, network) plus a wide "now playing" card underneath.
-- Loaded by conky.conf; conky_main runs on every update.

require 'cairo'
require 'cairo_xlib'

local CARD, GAP, RADIUS = 164, 14, 22
local MUSIC_H = 96

local FONT = 'Noto Sans CJK SC'           -- has Latin and Chinese (song titles)
local FONT_LIGHT = 'Noto Sans CJK SC Light'
local FONT_BOLD = 'Noto Sans CJK SC Medium'
local ICONS = 'Hack Nerd Font'

-- Nord
local BG      = {0.180, 0.204, 0.251, 0.80}
local EDGE    = {1, 1, 1, 0.06}
local TEXT    = {0.925, 0.937, 0.957, 1}
local DIM     = {0.847, 0.871, 0.914, 0.55}
local TRACK   = {1, 1, 1, 0.10}
local CYAN    = {0.533, 0.753, 0.816, 1}
local BLUE    = {0.506, 0.631, 0.757, 1}
local GREEN   = {0.639, 0.745, 0.549, 1}
local YELLOW  = {0.922, 0.796, 0.545, 1}
local ORANGE  = {0.816, 0.529, 0.439, 1}
local PURPLE  = {0.706, 0.557, 0.678, 1}

local WEATHER_ICONS = {
    ['01d'] = 0xe30d, ['01n'] = 0xe32b, ['02d'] = 0xe302, ['02n'] = 0xe37e,
    ['03'] = 0xe33d, ['04'] = 0xe312, ['09'] = 0xe318,
    ['10d'] = 0xe308, ['10n'] = 0xe336, ['11d'] = 0xe305, ['11n'] = 0xe325,
    ['13d'] = 0xe30a, ['13n'] = 0xe32a, ['50'] = 0xe313,
}

-- ---------------------------------------------------------------- data

-- Run a shell command at most every `ttl` seconds and reuse its output in between
local cache = {}
local function cached(cmd, ttl)
    local c = cache[cmd]
    if not c or os.time() - c.at >= ttl then
        local p = io.popen(cmd .. ' 2>/dev/null')
        local out = p and p:read('*a') or ''
        if p then p:close() end
        c = {at = os.time(), out = out:gsub('%s+$', '')}
        cache[cmd] = c
    end
    return c.out
end

local function split(s, sep)
    local t = {}
    for field in (s .. sep):gmatch('(.-)' .. sep) do t[#t + 1] = field end
    return t
end

local function num(s) return tonumber(s) or 0 end

local function weather()
    local w = split(cached([[jq -r '.current | [.name, .weather[0].main, .weather[0].icon,
        (.main.temp|round), (.main.temp_max|round), (.main.temp_min|round),
        .main.humidity, .wind.speed] | @tsv' ~/.cache/polybar-weather.json]], 300), '\t')
    if #w < 8 then return nil end
    return {city = w[1], desc = w[2], icon = w[3], temp = w[4], high = w[5], low = w[6], hum = w[7], wind = w[8]}
end

local function music()
    -- '|' means "or" in mpc format strings, so fields are separated by '@@'
    local st = split(cached("mpc status '%state%@@%currenttime%@@%totaltime%@@%percenttime%'", 1), '@@')
    local cur = split(cached("mpc current -f '%title%@@%artist%'", 1), '@@')
    return {
        state = st[1] or 'stopped', elapsed = st[2] or '', total = st[3] or '',
        pct = num((st[4] or ''):match('%d+')) / 100,
        title = cur[1] ~= '' and cur[1] or nil, artist = cur[2] or '',
    }
end

-- Download history for the sparkline in the network card
local history, HISTORY_LEN = {}, 40

-- ---------------------------------------------------------------- drawing

local cr

local function rgba(c, a) cairo_set_source_rgba(cr, c[1], c[2], c[3], a or c[4]) end

local function rounded(x, y, w, h, r)
    r = math.min(r, w / 2, h / 2)
    cairo_new_sub_path(cr)
    cairo_arc(cr, x + w - r, y + r, r, -math.pi / 2, 0)
    cairo_arc(cr, x + w - r, y + h - r, r, 0, math.pi / 2)
    cairo_arc(cr, x + r, y + h - r, r, math.pi / 2, math.pi)
    cairo_arc(cr, x + r, y + r, r, math.pi, 3 * math.pi / 2)
    cairo_close_path(cr)
end

local function card(x, y, w, h)
    rounded(x, y, w, h, RADIUS)
    rgba(BG)
    cairo_fill_preserve(cr)
    rgba(EDGE)
    cairo_set_line_width(cr, 1)
    cairo_stroke(cr)
end

local function font(face, size)
    cairo_select_font_face(cr, face, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, size)
end

local function width_of(s)
    local ext = cairo_text_extents_t:create()
    cairo_text_extents(cr, s, ext)
    return ext.x_advance
end

-- Shorten s with an ellipsis until it fits in max_w
local function fit(s, max_w)
    if width_of(s) <= max_w then return s end
    local chars = {}
    for _, c in utf8.codes(s) do chars[#chars + 1] = utf8.char(c) end
    while #chars > 0 and width_of(table.concat(chars) .. '…') > max_w do
        chars[#chars] = nil
    end
    return table.concat(chars) .. '…'
end

-- align: 'left' (x is the left edge) or 'right' (x is the right edge)
local function text(x, y, s, face, size, color, align, max_w)
    font(face, size)
    if max_w then s = fit(s, max_w) end
    if align == 'right' then x = x - width_of(s) end
    rgba(color)
    cairo_move_to(cr, x, y)
    cairo_show_text(cr, s)
end

local function bar(x, y, w, h, frac, color)
    rounded(x, y, w, h, h / 2)
    rgba(TRACK)
    cairo_fill(cr)
    frac = math.max(0, math.min(1, frac))
    if frac > 0 then
        rounded(x, y, math.max(h, w * frac), h, h / 2)
        rgba(color)
        cairo_fill(cr)
    end
end

-- ---------------------------------------------------------------- cards

local PAD = 16

local function clock_card(x, y)
    card(x, y, CARD, CARD)
    text(x + PAD, y + PAD + 12, os.date('%A'):upper(), FONT_BOLD, 12, CYAN)
    text(x + PAD - 2, y + 86, os.date('%H:%M'), FONT_LIGHT, 50, TEXT)
    text(x + PAD, y + 112, os.date('%B ') .. tonumber(os.date('%d')) .. os.date(', %Y'), FONT, 13, DIM)
    text(x + PAD, y + CARD - PAD, 'Week ' .. os.date('%V') .. '  ·  Day ' .. tonumber(os.date('%j')), FONT, 11, DIM)
end

local function weather_card(x, y)
    card(x, y, CARD, CARD)
    local w = weather()
    if not w then
        text(x + PAD, y + PAD + 12, 'WEATHER', FONT_BOLD, 12, YELLOW)
        text(x + PAD, y + 80, 'No data', FONT, 14, DIM)
        return
    end
    text(x + PAD, y + PAD + 12, w.city:upper(), FONT_BOLD, 12, YELLOW, 'left', CARD - 2 * PAD - 30)
    local glyph = WEATHER_ICONS[w.icon] or WEATHER_ICONS[w.icon:sub(1, 2)] or 0xe302
    text(x + CARD - PAD, y + PAD + 20, utf8.char(glyph), ICONS, 24, YELLOW, 'right')
    text(x + PAD - 2, y + 86, w.temp .. '°', FONT_LIGHT, 50, TEXT)
    text(x + PAD, y + 112, w.desc, FONT, 13, DIM)
    text(x + PAD, y + CARD - PAD - 16, 'H ' .. w.high .. '°  L ' .. w.low .. '°', FONT, 11, DIM)
    text(x + PAD, y + CARD - PAD, string.format('%s%%  ·  %.1f m/s', w.hum, num(w.wind)), FONT, 11, DIM)
end

local function system_card(x, y)
    card(x, y, CARD, CARD)
    local right = x + CARD - PAD
    local inner = CARD - 2 * PAD
    text(x + PAD, y + PAD + 12, 'SYSTEM', FONT_BOLD, 12, GREEN)
    text(right, y + PAD + 12, 'up ' .. conky_parse('${uptime_short}'), FONT, 11, DIM, 'right')

    local temp = cached("sensors | awk '/Tctl:/ {print $2}'", 5):gsub('^%+', '')
    local rows = {
        {'CPU', conky_parse('${cpu cpu0}') .. '%' .. (temp ~= '' and '  ' .. temp or ''), num(conky_parse('${cpu cpu0}')) / 100, GREEN},
        {'RAM', conky_parse('${mem}'), num(conky_parse('${memperc}')) / 100, BLUE},
        {'DISK', conky_parse('${fs_used /}') .. ' / ' .. conky_parse('${fs_size /}'), num(conky_parse('${fs_used_perc /}')) / 100, PURPLE},
    }
    for i, r in ipairs(rows) do
        local ry = y + 30 + i * 36
        text(x + PAD, ry, r[1], FONT_BOLD, 11, DIM)
        text(right, ry, r[2], FONT, 11, TEXT, 'right')
        bar(x + PAD, ry + 7, inner, 5, r[3], r[4])
    end
end

local function network_card(x, y)
    card(x, y, CARD, CARD)
    local iface = 'wlo1'
    local down = num(conky_parse('${downspeedf ' .. iface .. '}'))   -- KiB/s
    local up = num(conky_parse('${upspeedf ' .. iface .. '}'))
    table.insert(history, down)
    if #history > HISTORY_LEN then table.remove(history, 1) end

    local function speed(kib)
        if kib >= 1024 then return string.format('%.1f MB/s', kib / 1024) end
        return string.format('%.0f KB/s', kib)
    end

    text(x + PAD, y + PAD + 12, 'NETWORK', FONT_BOLD, 12, BLUE)
    text(x + CARD - PAD, y + PAD + 12, conky_parse('${addr ' .. iface .. '}'), FONT, 10, DIM, 'right')
    text(x + PAD, y + 62, utf8.char(0xf063) .. ' ', ICONS, 13, BLUE)
    text(x + PAD + 16, y + 62, speed(down), FONT_BOLD, 17, TEXT)
    text(x + PAD, y + 86, utf8.char(0xf062) .. ' ', ICONS, 13, ORANGE)
    text(x + PAD + 16, y + 86, speed(up), FONT, 13, DIM)

    -- Sparkline of the last HISTORY_LEN seconds of download speed
    local gx, gy, gw, gh = x + PAD, y + CARD - PAD - 34, CARD - 2 * PAD, 34
    local peak = 1
    for _, v in ipairs(history) do peak = math.max(peak, v) end
    local step = gw / (HISTORY_LEN - 1)
    local x0 = gx + gw - (#history - 1) * step
    cairo_move_to(cr, x0, gy + gh)
    for i, v in ipairs(history) do
        cairo_line_to(cr, x0 + (i - 1) * step, gy + gh - v / peak * gh)
    end
    cairo_line_to(cr, gx + gw, gy + gh)
    cairo_close_path(cr)
    rgba(BLUE, 0.25)
    cairo_fill(cr)
end

local function music_card(x, y, w)
    card(x, y, w, MUSIC_H)
    local m = music()
    local art = MUSIC_H - 2 * PAD
    rounded(x + PAD, y + PAD, art, art, 12)
    rgba(m.state == 'playing' and PURPLE or TRACK)
    cairo_fill(cr)
    text(x + PAD + art / 2 - 9, y + PAD + art / 2 + 9, utf8.char(0xf001), ICONS, 22, BG, 'left')

    local tx = x + PAD + art + 14
    local tw = x + w - PAD - tx
    if not m.title or m.state == 'stopped' then
        text(tx, y + MUSIC_H / 2 + 6, 'Not Playing', FONT_BOLD, 15, DIM)
        return
    end
    local status = m.state == 'paused' and 'PAUSED' or 'NOW PLAYING'
    text(tx, y + PAD + 10, status, FONT_BOLD, 10, PURPLE)
    text(tx, y + PAD + 30, m.title, FONT_BOLD, 15, TEXT, 'left', tw)
    text(tx, y + PAD + 48, m.artist, FONT, 12, DIM, 'left', tw - 80)
    text(x + w - PAD, y + PAD + 48, m.elapsed .. ' / ' .. m.total, FONT, 11, DIM, 'right')
    bar(tx, y + MUSIC_H - PAD - 4, tw, 4, m.pct, PURPLE)
end

-- ---------------------------------------------------------------- entry point

function conky_main()
    if conky_window == nil then return end
    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable,
        conky_window.visual, conky_window.width, conky_window.height)
    cr = cairo_create(cs)

    local x1, x2 = 1, 1 + CARD + GAP
    local y1, y2 = 1, 1 + CARD + GAP
    clock_card(x1, y1)
    weather_card(x2, y1)
    system_card(x1, y2)
    network_card(x2, y2)
    music_card(x1, y2 + CARD + GAP, 2 * CARD + GAP)

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr = nil
end
