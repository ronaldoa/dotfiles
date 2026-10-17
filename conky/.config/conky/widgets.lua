-- Apple-style desktop widgets drawn with Cairo: rounded translucent cards in a 2x2 grid
-- (clock, weather, system, network) plus wide storage and "now playing" cards underneath.
-- Loaded by conky.conf; conky_main runs on every update. Drawing helpers live in lib.lua.

local L = dofile(os.getenv('HOME') .. '/.config/conky/lib.lua')
local cached, split, num = L.cached, L.split, L.num
local rgba, rounded, card, text, bar = L.rgba, L.rounded, L.card, L.text, L.bar
local FONT, FONT_LIGHT, FONT_BOLD, ICONS = L.FONT, L.FONT_LIGHT, L.FONT_BOLD, L.ICONS
local BG, TEXT, DIM, TRACK = L.BG, L.TEXT, L.DIM, L.TRACK
local CYAN, BLUE, GREEN, YELLOW, ORANGE, PURPLE = L.CYAN, L.BLUE, L.GREEN, L.YELLOW, L.ORANGE, L.PURPLE

local CARD, GAP = 164, 14
local MUSIC_H, STORAGE_H = 96, 134

local cr

-- Same detector and 3-second cache as Polybar; no fixed sensor names or network devices.
local function hardware()
    local data = {}
    for key, value in cached('~/.config/i3/bin/hardware conky', 3):gmatch('([^=\n]+)=([^\n]*)') do
        data[key] = value
    end
    return data
end

-- ---------------------------------------------------------------- data

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
    text(x + CARD - PAD, y + PAD + 20, L.weather_icon(w.icon), ICONS, 24, YELLOW, 'right')
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

    local hw = hardware()
    local temp = hw.cpu_temp or ''
    local rows = {
        {'CPU', conky_parse('${cpu cpu0}') .. '%' .. (temp ~= '' and '  ' .. temp or ''), num(conky_parse('${cpu cpu0}')) / 100, GREEN},
        {'RAM', conky_parse('${mem}') .. '/' .. conky_parse('${memmax}'), num(conky_parse('${memperc}')) / 100, BLUE},
    }
    if hw.gpu and hw.gpu ~= '' then
        rows[#rows + 1] = {'GPU', hw.gpu, nil, ORANGE}
    end
    if hw.battery and hw.battery ~= '' then
        rows[#rows + 1] = {'BAT', hw.battery, nil, YELLOW}
    end
    local spacing = 108 / #rows
    for i, r in ipairs(rows) do
        local ry = y + 30 + i * spacing
        text(x + PAD, ry, r[1], FONT_BOLD, 11, DIM)
        text(right, ry, r[2], FONT, 11, TEXT, 'right', inner - 30)
        if r[3] then bar(x + PAD, ry + 7, inner, 5, r[3], r[4]) end
    end
end

local function network_card(x, y)
    card(x, y, CARD, CARD)
    local hw = hardware()
    local iface = hw.network_iface or ''
    local down, up = num(hw.network_down), num(hw.network_up) -- KiB/s
    table.insert(history, down)
    if #history > HISTORY_LEN then table.remove(history, 1) end

    local function speed(kib)
        if kib >= 1024 then return string.format('%.1f MB/s', kib / 1024) end
        return string.format('%.0f KB/s', kib)
    end

    text(x + PAD, y + PAD + 12, 'NETWORK', FONT_BOLD, 12, BLUE)
    text(x + CARD - PAD, y + PAD + 12, iface ~= '' and (hw.network_ip or iface) or 'Offline', FONT, 10, DIM, 'right', CARD - 2 * PAD - 55)
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

local function storage_card(x, y, w)
    card(x, y, w, STORAGE_H)
    text(x + PAD, y + PAD + 12, 'STORAGE', FONT_BOLD, 12, PURPLE)
    local hw = hardware()
    local count = num(hw.disk_count)
    if count == 0 then
        text(x + PAD, y + 76, 'No mounted local disks', FONT, 13, DIM)
        return
    end
    local pages = math.ceil(count / 3)
    local page = math.floor(os.time() / 10) % pages
    if pages > 1 then
        text(x + w - PAD, y + PAD + 12, string.format('%d / %d', page + 1, pages), FONT, 11, DIM, 'right')
    end
    for row = 1, 3 do
        local index = page * 3 + row
        if index > count then break end
        local prefix = 'disk_' .. index
        local ry = y + 24 + row * 30
        local pct = num(hw[prefix .. '_percent'])
        text(x + PAD, ry, hw[prefix .. '_mount'] or '', FONT_BOLD, 11, TEXT, 'left', w - 2 * PAD - 195)
        text(x + w - PAD, ry, (hw[prefix .. '_usage'] or '') .. string.format(' · %.0f%%', pct), FONT, 11, DIM, 'right', 190)
        bar(x + PAD, ry + 7, w - 2 * PAD, 5, pct / 100, pct >= 90 and ORANGE or PURPLE)
    end
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
    cr = L.begin(2 * CARD + GAP + 2, 2 * CARD + 3 * GAP + STORAGE_H + MUSIC_H + 2)
    if not cr then return end

    local x1, x2 = 1, 1 + CARD + GAP
    local y1, y2 = 1, 1 + CARD + GAP
    clock_card(x1, y1)
    weather_card(x2, y1)
    system_card(x1, y2)
    network_card(x2, y2)
    storage_card(x1, y2 + CARD + GAP, 2 * CARD + GAP)
    music_card(x1, y2 + CARD + 2 * GAP + STORAGE_H, 2 * CARD + GAP)

    L.finish()
end
