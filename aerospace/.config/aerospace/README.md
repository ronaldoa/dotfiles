# AeroSpace 配置（Mac）

把 Linux 上的 i3 配置（`i3/.config/i3/config`）翻译成 [AeroSpace](https://github.com/nikitabobko/AeroSpace)，让 Mac 上的平铺窗口操作和 i3 基本一样。Mac 上的 `Alt` 就是 `Option` 键。

> 这个配置是在 Linux 上写的，已经在 Mac 上用 AeroSpace 0.20.3 加载过（`aerospace reload-config` 不报错）。

## 安装

```sh
brew install --cask nikitabobko/tap/aerospace
brew install FelixKratz/formulae/borders     # 焦点窗口边框，相当于 i3 的彩色边框
brew install mpc                             # 可选：Ctrl+Cmd+M 等 mpd 快捷键要用

# 链接配置：和其他包一起由 bootstrap 链接（见仓库根目录的 INSTALL.md「Mac」一节）
brew install stow
~/dotfiles/bin/dotfiles-bootstrap
```

然后打开 AeroSpace，在「系统设置 → 隐私与安全性 → 辅助功能」里允许它。配置里设了 `start-at-login = true`，以后开机会自动启动。

## 建议的 macOS 设置

- **系统设置 → 桌面与程序坞 → 「显示器具有单独的空间」关掉**：AeroSpace 官方建议，多显示器时更稳定（改完要注销一次）。
- **终端里把 Option 当 Alt 用**：否则 `Alt+字母` 在终端里会打出特殊字符。alacritty 加 `[window] option_as_alt = "Both"`，WezTerm 设 `send_composed_key_when_left_alt_is_pressed = false`。不过 AeroSpace 的快捷键是全局抓取的，在终端里也照样生效，这一条只影响终端里的程序自己用 Alt。
- **Raycast 代替 rofi**：AeroSpace 只管窗口，启动器这类功能交给 Raycast。在 Raycast 里把这些命令的快捷键设成和 Linux 一样：

  | Linux 快捷键 | Raycast 命令 |
  |---|---|
  | `Alt+D` | 打开 Raycast（启动器） |
  | `Alt+O` | Switch Windows |
  | `Alt+Shift+V` | Clipboard History |
  | `Option+Cmd+.` | Search Emoji & Symbols（Mac 上 `Super` 对应 `Cmd`，`Cmd+.` 被系统占用，所以加个 Option） |

## 快捷键

和 i3 一样的部分：

| 按键 | 功能 |
|---|---|
| `Alt+h/j/k/l` 或方向键 | 切换焦点 |
| `Alt+Shift+h/j/k/l` 或方向键 | 移动窗口 |
| `Alt+Q` | 关闭窗口 |
| `Alt+F` | 全屏 |
| `Alt+Shift+Space` | 平铺 ⇄ 浮动 |
| `Alt+Shift+Q` | 切换横向 / 纵向排列 |
| `Alt+R` | 调整大小模式：`h/j/k/l` 或方向键调整，`=` 把所有窗口变成一样大，`Enter` / `Esc` / `Alt+R` 退出 |
| `Alt+1`…`Alt+9`、`Alt+0` | 切到工作区 1–10（再按一次当前工作区的数字回到上一个） |
| `Alt+Shift+数字` | 把窗口移到该工作区 |
| `Alt+Ctrl+数字` | 把窗口移到该工作区，并跟过去 |
| `` Alt+` `` | 回到上一个工作区 |
| `Alt+[` / `Alt+]` | 上一个 / 下一个工作区 |
| `Alt+Shift+C` | 重新加载配置 |
| `Alt+Enter` | Alacritty |
| `Alt+C` / `Alt+T` | Firefox / Thunderbird |
| `Alt+Shift+N` | 在 Finder 里打开主目录 |
| `Alt+Ctrl+O/B/T/L/C/G` | Obsidian / 哔哩哔哩 / Teams / LM Studio / VS Code / ChatGPT |
| `Alt+Ctrl+N` / `Alt+Ctrl+W` | 呼出 / 隐藏 Noi / 微信主窗口（模拟 scratchpad，见下面） |
| `Ctrl+Cmd+S` | 框选截图到剪贴板（i3 上是 `Super+S`） |
| `Ctrl+Cmd+M`、`Ctrl+Cmd+[ / ]` | mpd 播放暂停、上一首 / 下一首（i3 上是 `Super+M`、`Super+[ / ]`；Mac 上单独的 `Cmd+M`、`Cmd+[ / ]` 是最小化和后退 / 前进，所以多加一个 `Ctrl`） |

意思一样、但做法不同的：

| 按键 | i3 | AeroSpace |
|---|---|---|
| `Alt+;` / `Alt+V` | 下一个窗口横着 / 竖着切分 | AeroSpace 不能预先切分，改成把当前窗口和右边 / 下面的窗口合并成一组 |
| `Alt+S` / `Alt+W` | 堆叠 / 标签布局 | accordion 布局（窗口叠在一起，露出一条边），竖向 / 横向 |
| `Alt+E` | 切换平铺方向 | 回到平铺布局，再按切换方向 |

只有 AeroSpace 有的：

| 按键 | 功能 |
|---|---|
| `Alt+Shift+Tab` | 把整个工作区移到下一个显示器 |
| `Alt+Shift+;` | 维护模式：`r` 重置当前工作区的布局，`f` 平铺 ⇄ 浮动，`Backspace` 关掉除当前窗口外的所有窗口，`Esc` 重新加载配置并退出 |

## 窗口规则

工作区分配和 i3 一样：1 LibreOffice，2 JetBrains 全家，3 Firefox / Edge Dev，4 哔哩哔哩 / 网易云音乐，5 Steam，6 VirtualBox 虚拟机，8 Thunderbird / QQ / Telegram / Obsidian。
Noi 和微信不固定工作区，浮动在当前工作区上（和 i3 一样放在 scratchpad 里）。

## 模拟 scratchpad

AeroSpace 没有 scratchpad，`bin/scratchpad` 用一个不会切过去的工作区 `S` 代替：

- 窗口在前台：挪到 `S`，看起来就是藏起来了
- 窗口在 `S` 或别的工作区：设成浮动，挪到当前工作区并聚焦
- 程序没开 / 主窗口关掉了：`open -a` 打开

微信有好几个窗口（单独打开的聊天、看图），只有标题是「微信 / WeChat / Weixin」的主窗口会被藏起来。
和 i3 不同的地方：AeroSpace 不能用命令移动和缩放浮动窗口，所以呼出时窗口保持上次的位置和大小，不会自动居中；也没有滑入动画。
`S` 会出现在 `aerospace list-workspaces` 里，不要往里放别的窗口。

浮动：Steam、QQ、VirtualBox 管理器、计算器、系统设置、copyq、Raycast、画中画视频。系统对话框（打开 / 保存文件等）AeroSpace 默认就会浮动。

规则按程序名匹配（不区分大小写的子串），不用知道每个程序的 bundle id。如果某个程序没被分到正确的工作区，在终端运行 `aerospace list-apps` 看它的实际名字，再改 `aerospace.toml` 里对应的 `app-name-regex-substring`。

## i3 里有、这里没有的

AeroSpace 没有对应功能，或者 Mac 上交给别的工具：

- 通用的 scratchpad（`Alt+-` / `Alt+Shift+-`；只有 Noi 和微信用 `bin/scratchpad` 模拟了）、sticky、mark 跳转、聚焦父 / 子容器、平铺和浮动之间切换焦点
- 窗口间距开关（`Alt+G`）、`smart_gaps`（只有一个窗口时也保留间距）
- 下拉终端：用 WezTerm 或 iTerm2 的「热键窗口」
- 状态栏（polybar）：可以用 SketchyBar 做
- 桌面组件、天气 / 日历卡片（conky）：可以用 Übersicht 做
- 通知、锁屏、截图、色温：用系统自带的（锁屏是 `Ctrl+Cmd+Q`，色温是「夜览」）
- 频谱、动态壁纸、配色切换、快捷键速查
