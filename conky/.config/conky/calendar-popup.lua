-- Calendar popup card (click the clock in polybar to toggle): today on the left,
-- a month grid on the right (weeks start on Monday, today circled).
-- Click the ‹ › arrows or scroll over the card to change month; click the month name to come back.

local L = dofile(os.getenv('HOME') .. '/.config/conky/lib.lua')
local text, card, rgba = L.text, L.card, L.rgba
local FONT, FONT_LIGHT, FONT_BOLD = L.FONT, L.FONT_LIGHT, L.FONT_BOLD
local TEXT, DIM, RED, ICONS = L.TEXT, L.DIM, L.RED, L.ICONS

local W, H, PAD = 446, 250, 20
local SIDE = 150                -- width of the "today" panel
local CELL_W, CELL_H = 36, 27

-- Months away from the current one, changed by the mouse hook
local offset = 0
local hover                     -- 'prev', 'next', 'title' or nil

-- Clickable areas in window coordinates: {x1, y1, x2, y2}, filled in while drawing
local hit = {}

local function days_in(year, month)
    return os.date('*t', os.time {year = year, month = month + 1, day = 0}).day
end

function conky_calendar_popup()
    local cr = L.begin(W + 2, H + 2)
    if not cr then return end
    local x, y = 1, 1
    card(x, y, W, H, 0.96)

    local now = os.date('*t')
    local today = now.day
    local shown = os.date('*t', os.time {year = now.year, month = now.month + offset, day = 1})
    local year, month = shown.year, shown.month
    local is_current = offset == 0
    local days_in_year = os.date('*t', os.time {year = year, month = 12, day = 31}).yday

    -- Today
    text(x + PAD, y + 38, os.date('%A'):upper(), FONT_BOLD, 13, RED)
    text(x + PAD - 3, y + 118, tostring(today), FONT_LIGHT, 76, TEXT)
    text(x + PAD, y + 148, os.date('%B %Y'), FONT, 14, DIM)
    text(x + PAD, y + H - PAD - 20, 'Week ' .. os.date('%V'), FONT, 11, DIM)
    text(x + PAD, y + H - PAD, string.format('Day %d · %d left', now.yday, days_in_year - now.yday), FONT, 11, DIM)

    -- Divider
    rgba({1, 1, 1, 0.08})
    cairo_rectangle(cr, x + SIDE, y + PAD, 1, H - 2 * PAD)
    cairo_fill(cr)

    -- Month grid header: month name (plus the year when it isn't this year) and the arrows
    local gx = x + SIDE + PAD
    local title = os.date('%B', os.time(shown)):upper()
    if year ~= now.year then title = title .. ' ' .. year end
    text(gx + 6, y + 38, title, FONT_BOLD, 13, (is_current or hover == 'title') and RED or TEXT)
    if not is_current then
        text(gx + 6 + L.width_of(title) + 10, y + 38, 'Today', FONT, 10, DIM)
    end
    hit.title = {gx, y + 18, gx + 7 * CELL_W - 70, y + 46}

    local right = gx + 7 * CELL_W
    for _, a in ipairs {{'prev', 0xf053, right - 50}, {'next', 0xf054, right - 18}} do
        local name, glyph, ax = a[1], a[2], a[3]
        if hover == name then
            cairo_arc(cr, ax, y + 33, 13, 0, 2 * math.pi)
            rgba({1, 1, 1, 0.10})
            cairo_fill(cr)
        end
        text(ax, y + 38, utf8.char(glyph), ICONS, 13, hover == name and TEXT or DIM, 'center')
        hit[name] = {ax - 15, y + 18, ax + 15, y + 48}
    end
    local labels = {'M', 'T', 'W', 'T', 'F', 'S', 'S'}
    for col = 1, 7 do
        text(gx + (col - 0.5) * CELL_W, y + 64, labels[col], FONT_BOLD, 10, col > 5 and {1, 1, 1, 0.3} or DIM, 'center')
    end

    -- Column of the 1st (Monday = 1); leading/trailing cells show the neighbouring months, faded
    local first = (os.date('*t', os.time {year = year, month = month, day = 1}).wday + 5) % 7 + 1
    local prev_days = days_in(year, month - 1)
    local count = days_in(year, month)
    local rows = math.ceil((first - 1 + count) / 7)
    local top = y + 92
    for cell = 1, rows * 7 do
        local col = (cell - 1) % 7 + 1
        local row = (cell - 1) // 7
        local day = cell - first + 1
        local cx, cy = gx + (col - 0.5) * CELL_W, top + row * CELL_H
        local label, color
        if day < 1 then
            label, color = prev_days + day, {1, 1, 1, 0.15}
        elseif day > count then
            label, color = day - count, {1, 1, 1, 0.15}
        else
            label, color = day, col > 5 and {1, 1, 1, 0.45} or TEXT
        end
        if is_current and day == today then
            cairo_arc(cr, cx, cy - 4, 13, 0, 2 * math.pi)
            rgba(RED)
            cairo_fill(cr)
            text(cx, cy + 1, tostring(label), FONT_BOLD, 13, {1, 1, 1, 1}, 'center')
        else
            text(cx, cy + 1, tostring(label), FONT, 13, color, 'center')
        end
    end

    L.finish()
end

-- Hit areas are in drawing coordinates; events are in window pixels
local function inside(r, ev)
    local x, y = ev.x / L.scale, ev.y / L.scale
    return r and x >= r[1] and x <= r[3] and y >= r[2] and y <= r[4]
end

local function area(ev)
    for _, name in ipairs {'prev', 'next', 'title'} do
        if inside(hit[name], ev) then return name end
    end
end

function conky_calendar_mouse(ev)
    if ev.type == 'button_down' and (ev.button == 'left' or ev.button == 1) then
        local a = area(ev)
        if a == 'prev' then offset = offset - 1
        elseif a == 'next' then offset = offset + 1
        elseif a == 'title' then offset = 0
        end
    elseif ev.type == 'mouse_scroll' then
        offset = offset + (ev.direction == 'up' and -1 or 1)
    elseif ev.type == 'mouse_move' then
        hover = area(ev)
    elseif ev.type == 'mouse_leave' then
        hover = nil
    end
    return true
end
