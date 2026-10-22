# CLAUDE.md

GNU stow 管理的 dotfiles：每个顶层目录是一个包，`bin/dotfiles-bootstrap` 把它们链接进 `$HOME`，
再叠加 `hosts/<主机名>/` 里的本机设置。提交信息用中文，格式 `范围: 做了什么`。

## i3 快捷键分组规则

配置在 `i3/.config/i3/config`（`$mod` = Alt，`$mod1` = Super）。新加或改快捷键时先按这张表选组，不要跨组：

| 修饰键 | 管什么 | 例子 |
|---|---|---|
| `Alt` | i3 窗口操作，加上最常用的几个程序 | `h/j/k/l` 焦点、`f` 全屏、`q` 关窗口、`Enter` 终端、`d` rofi、`c` Firefox |
| `Alt+Shift` | `Alt` 那个操作的"加强版"，以及 i3 自身 | `h/j/k/l` 移动窗口、`数字` 把窗口移到工作区、`c` / `r` 重载 / 重启 i3 |
| `Alt+Ctrl` | 只用来打开程序，字母取程序名首字母（被占了就取一个相关的字母） | `o` Obsidian、`b` 哔哩哔哩、`t` Teams、`g` ChatGPT、`c` VS Code（Code）、`r` OBS（record） |
| `Super` | 桌面功能（不是某个程序） | 截图、录屏、音乐、通知、歌词、频谱、组件、壁纸、配色、护眼、锁屏 |
| `Super+Shift` / `Super+Ctrl` / `Super+Alt` | `Super` 那个功能的变体 | `s` 框选截图 → `Shift+s` 全屏 / `Ctrl+s` 延时 / `Alt+s` 到剪贴板；`Esc` 锁屏 → `Shift+Esc` 电源菜单 |

- 两组相同的按键表示同一个意思：`[` / `]` 是上一个 / 下一个（`Alt` 换工作区，`Super` 换歌）。
- 历史遗留的例外，不要照着学，也不要顺手改：Thunar（`Alt+Shift+n`）、
  copyq（`Alt+Shift+v`）、`Alt+Tab` 是"运行命令"。
- 这台键盘没有 `Print` 键，截图不要绑到 `Print` 上。

加快捷键时：
1. 先 `grep` 确认按键没被占用（i3 不允许后面的 `bindsym` 覆盖前面的，`hosts/` 里的 `i3.conf` 也要查）。
2. 在 `bindsym` 正上方写一行注释：`bin/keyhelp`（`Alt+/`）用它当说明。
3. 同步更新 `i3/.config/i3/README.md` 的快捷键表格；脚本注释里写了按键的（如 `rofi/bin/powermenu`）也要改。
4. `i3 -C -c ~/.config/i3/config` 检查语法，再 `i3-msg reload`。

macOS 的 `aerospace/` 有自己的一套按键，不受这张表约束。要和 i3 的 `Super` 组对应时用 `Ctrl+Cmd`，不要用单独的 `Cmd`：
`Cmd+字母` 是 macOS 和各个程序自己的快捷键（如 `Cmd+M` 最小化、`Cmd+[ / ]` 后退 / 前进），aerospace 全局抓键会让它们失效。
