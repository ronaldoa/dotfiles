-- WezTerm, set up to look and behave like alacritty/.config/alacritty/alacritty.toml.
--
-- Colours, font size and the startup shell are read from alacritty's TOML files
-- rather than copied here, so each still lives in one place:
--   ~/.config/alacritty/colors.toml          default colours (Nord)
--   ~/.cache/theme/alacritty.toml            written by ~/.config/i3/bin/theme (Super+T); empty = default
--   ~/.config/dotfiles-host/alacritty.toml   per-machine font size, stowed from hosts/<hostname>/
--   ~/.config/alacritty/alacritty.toml       terminal.shell: attach to an idle tmux session or start one
-- Later files win. All are on the reload watch list, so a theme switch recolours open windows.
local wezterm = require 'wezterm'

local home = os.getenv('HOME')
local function read_toml(path)
  path = home .. path
  wezterm.add_to_config_reload_watch_list(path)
  local f = io.open(path)
  if not f then return {} end
  local text = f:read('a')
  f:close()
  local ok, t = pcall(wezterm.serde.toml_decode, text)
  return ok and t or {}
end

local alacritty = read_toml('/.config/alacritty/alacritty.toml')
local sources = {
  read_toml('/.config/alacritty/colors.toml'),
  read_toml('/.cache/theme/alacritty.toml'),
  read_toml('/.config/dotfiles-host/alacritty.toml'),
}

-- alacritty writes colours as 0xRRGGBB, wezterm wants #RRGGBB
local function hex(c) return (c:gsub('^0x', '#')) end
local names = { 'black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white' }
local primary, normal, bright, font_size = {}, {}, {}, nil
for _, t in ipairs(sources) do
  local c = t.colors or {}
  for k, v in pairs(c.primary or {}) do primary[k] = v end
  for k, v in pairs(c.normal or {}) do normal[k] = v end
  for k, v in pairs(c.bright or {}) do bright[k] = v end
  if t.font and t.font.size then font_size = t.font.size end
end
local function palette(p)
  local out = {}
  for i, n in ipairs(names) do out[i] = hex(p[n] or '#000000') end
  return out
end

local config = wezterm.config_builder()

config.font = wezterm.font 'Hack Nerd Font'
if font_size then config.font_size = font_size end

config.colors = {
  foreground = hex(primary.foreground or '#d8dee9'),
  background = hex(primary.background or '#2e3440'),
  cursor_bg = hex(primary.foreground or '#d8dee9'),
  cursor_border = hex(primary.foreground or '#d8dee9'),
  cursor_fg = hex(primary.background or '#2e3440'),
  ansi = palette(normal),
  brights = palette(bright),
}
config.bold_brightens_ansi_colors = 'No'
config.default_cursor_style = 'SteadyBlock'

config.initial_cols = 120
config.initial_rows = 30
config.window_padding = { left = 20, right = 20, top = 10, bottom = 10 }
-- tmux does the tabs and splits
config.enable_tab_bar = false
config.window_close_confirmation = 'NeverPrompt'
config.check_for_updates = false

config.scrollback_lines = 100000

local shell = (alacritty.terminal or {}).shell
if shell and shell.program then
  config.default_prog = { shell.program, table.unpack(shell.args or {}) }
end

-- Selecting text copies it to the clipboard too, like alacritty's save_to_clipboard
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor 'ClipboardAndPrimarySelection',
  },
}
config.selection_word_boundary = ',│`|:"\' ()[]{}<>\t@='

return config
