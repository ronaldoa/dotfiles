-- Shared helpers for the Cairo-drawn conky widgets (widgets.lua, weather-popup.lua, calendar-popup.lua):
-- palette, fonts, cached shell commands and rounded-card drawing.
-- Usage: local L = dofile(os.getenv('HOME') .. '/.config/conky/lib.lua')
--        L.begin(); ...draw...; L.finish()   -- inside the conky_* draw hook

require 'cairo'

local L = {}

L.RADIUS = 22

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
local RED     = {0.749, 0.380, 0.416, 1}
local PURPLE  = {0.706, 0.557, 0.678, 1}

local WEATHER_ICONS = {
    ['01d'] = 0xe30d, ['01n'] = 0xe32b, ['02d'] = 0xe302, ['02n'] = 0xe37e,
    ['03'] = 0xe33d, ['04'] = 0xe312, ['09'] = 0xe318,
    ['10d'] = 0xe308, ['10n'] = 0xe336, ['11d'] = 0xe305, ['11n'] = 0xe325,
    ['13d'] = 0xe30a, ['13n'] = 0xe32a, ['50'] = 0xe313,
}

L.FONT, L.FONT_LIGHT, L.FONT_BOLD, L.ICONS = FONT, FONT_LIGHT, FONT_BOLD, ICONS
L.BG, L.EDGE, L.TEXT, L.DIM, L.TRACK = BG, EDGE, TEXT, DIM, TRACK
L.CYAN, L.BLUE, L.GREEN, L.YELLOW, L.ORANGE, L.PURPLE, L.RED = CYAN, BLUE, GREEN, YELLOW, ORANGE, PURPLE, RED

-- OpenWeatherMap icon code ("04d") -> Nerd Font weather glyph
function L.weather_icon(code)
    return utf8.char(WEATHER_ICONS[code] or WEATHER_ICONS[(code or ''):sub(1, 2)] or 0xe302)
end

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

L.cached, L.split, L.num = cached, split, num

-- ---------------------------------------------------------------- drawing

local cr

-- Start drawing on the conky window; returns the cairo context (nil before the window exists).
-- conky_surface() belongs to conky, so only the context is ours to destroy.
function L.begin()
    if conky_window == nil then return nil end
    cr = cairo_create(conky_surface())
    return cr
end

function L.finish()
    cairo_destroy(cr)
    cr = nil
end

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

-- alpha overrides the background opacity (popups over windows need a more solid card)
local function card(x, y, w, h, alpha)
    rounded(x, y, w, h, L.RADIUS)
    rgba(BG, alpha)
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

-- align: 'left' (x is the left edge), 'right' (x is the right edge) or 'center'
local function text(x, y, s, face, size, color, align, max_w)
    font(face, size)
    if max_w then s = fit(s, max_w) end
    if align == 'right' then x = x - width_of(s) elseif align == 'center' then x = x - width_of(s) / 2 end
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

L.rgba, L.rounded, L.card, L.font, L.width_of, L.fit, L.text, L.bar = rgba, rounded, card, font, width_of, fit, text, bar

return L
