local wezterm = require 'wezterm'

return {
  -- 字体设置：使用已安装的 Nerd Font（建议 Hack 或 JetBrainsMono）
  font = wezterm.font_with_fallback {
    "Hack Nerd Font",
  },
  font_size = 14.0,

  -- 主题配色
  color_scheme = "Catppuccin Mocha",  -- 可选 Dracula, Gruvbox Dark, OneHalfDark 等

  -- 窗口边距
  window_padding = {
    left = 8, right = 8, top = 4, bottom = 4,
  },

  -- 标签栏设置
  enable_tab_bar = true,
  hide_tab_bar_if_only_one_tab = true,
  use_fancy_tab_bar = false,

  -- 启用 Wayland（如果适用）
  enable_wayland = false,

  -- 默认启动程序（可选：自动 tmux）
  default_prog = { "zsh", "-l" },

  -- 快捷键绑定示例（可自定义）
  keys = {
    {key="Enter", mods="ALT", action="ToggleFullScreen"},
    {key="t", mods="CTRL|SHIFT", action=wezterm.action.SpawnTab("CurrentPaneDomain")},
    {key="w", mods="CTRL|SHIFT", action=wezterm.action.CloseCurrentTab{confirm=true}},
    {key="d", mods="CTRL|SHIFT", action=wezterm.action.SplitHorizontal{domain="CurrentPaneDomain"}},
    {key="v", mods="CTRL|SHIFT", action=wezterm.action.SplitVertical{domain="CurrentPaneDomain"}},
  },

  -- 滚动配置
  scrollback_lines = 5000,

  -- 动画关闭（加速渲染）
  animation_fps = 1,
  cursor_blink_rate = 0,
}

