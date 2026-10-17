-- Calendar popup card (click the clock in polybar to toggle): today on the left,
-- this month's grid on the right (weeks start on Monday, today circled).

local L = dofile(os.getenv('HOME') .. '/.config/conky/lib.lua')
local text, card, rgba = L.text, L.card, L.rgba
local FONT, FONT_LIGHT, FONT_BOLD = L.FONT, L.FONT_LIGHT, L.FONT_BOLD
local TEXT, DIM, RED = L.TEXT, L.DIM, L.RED

local W, H, PAD = 446, 250, 20
local SIDE = 150                -- width of the "today" panel
local CELL_W, CELL_H = 36, 27

local function days_in(year, month)
    return os.date('*t', os.time {year = year, month = month + 1, day = 0}).day
end

function conky_calendar_popup()
    local cr = L.begin()
    if not cr then return end
    local x, y = 1, 1
    card(x, y, W, H, 0.96)

    local now = os.date('*t')
    local year, month, today = now.year, now.month, now.day
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

    -- Month grid
    local gx = x + SIDE + PAD
    text(gx + 6, y + 38, os.date('%B'):upper(), FONT_BOLD, 13, RED)
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
        if day == today then
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
