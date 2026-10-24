-- ThinkPad T460p -- 14" 1920x1080 panel (308x173 mm), no Xft.dpi set.
--
-- Returns config keys that wezterm.lua applies last. The font size itself comes from
-- alacritty.toml next to this file; this only makes wezterm render it at the same size.
-- Without Xft.dpi, alacritty (winit) derives its scale from the panel's physical size:
-- sqrt(1920*1080 / (308*173)) px/mm * 25.4/96, rounded to twelfths = 20/12 ≈ 1.67,
-- while wezterm assumes 96 dpi, so size 10 came out at ~60% of alacritty's.
-- Plain `dpi` has no effect on X11 (wezterm 20260716 replaces it with the screen's own dpi);
-- dpi_by_screen does work, and leaves an external monitor at its default.
return {
  dpi_by_screen = { ['eDP-1'] = 160 }, -- 96 * 20/12
}
