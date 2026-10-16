# i3 配置

i3 4.25（自带 gaps），Nord 配色，状态栏用 polybar。

- `Alt` = `$mod`（主修饰键，大部分快捷键用它），`Super`（Win 键）= `$mod1`（特效类快捷键用它）。比如 `Alt+T` 是 Thunderbird，`Super+T` 是配色切换
- 按 `Alt+/` 可以在 rofi 里搜索所有快捷键（`bin/keyhelp`，直接读取 i3 当前加载的配置，所以永远和实际一致）

## 目录结构

```
config              i3 主配置
bin/
  i3bar             (重)启动 polybar
  lock              锁屏：随机背景图 + 时钟 + 输入动画圈（i3lock-color）
  keyhelp           快捷键速查（Alt+/）
  lyrics            mpd 当前歌曲的同步歌词：状态栏单行 / 浮动歌词窗口
  music-pick        rofi 搜索 mpd 曲库并播放
  chatgpt-toggle    ChatGPT 网页放在 scratchpad 里，一键呼出/隐藏
  edid-check        登录时检查 xorg 里固定的显示器 EDID 是否还对得上
  ws-icons          工作区名字后面显示程序图标
  dropdown          下拉终端
  cava-toggle       屏幕底部的音乐频谱窗口
  widgets           开关 conky 桌面组件
  livewall          视频动态壁纸
  theme             配色切换：Nord ⇄ pywal（从壁纸取色）
themes/
  nord.Xresources   Nord 配色（theme 脚本用）
polybar/
  config            状态栏
  script/           天气、日历弹窗、频谱
```

相关的其他目录（同一个 dotfiles 仓库）：`picom/`（特效）、`cava/`（频谱配色）、`conky/`（桌面组件）、`alacritty/colors.toml`（终端默认配色）、`rofi/config.rasi`（引入主题配色）。

## 开机自启

| 程序 | 作用 |
|---|---|
| xss-lock + `bin/lock` | 5 分钟无操作或休眠前锁屏 |
| `bin/theme restore` | 恢复上次选的配色（Nord / pywal） |
| `bin/ws-icons` | 工作区图标（i3 重启时自动换新的一份） |
| `bin/widgets start` | conky 桌面组件 |
| xrandr | HDMI-0 设为 2560x1440 @ 100Hz |
| polkit-gnome | 图形程序要 root 时弹出密码框（pamac、gparted 等） |
| nitrogen --restore | 恢复壁纸（先运行一次 `nitrogen` 选好壁纸） |
| udiskie | U 盘自动挂载，带托盘图标 |
| autotiling | 新窗口自动沿当前窗口较长的一边切分 |
| setxkbmap | Caps Lock 和 Ctrl 互换 |
| fcitx5 | 输入法 |
| xfce4-power-manager | 电源管理 |
| copyq | 剪贴板历史 |
| picom | 合成器（阴影、透明、淡入淡出） |
| polybar | 状态栏 |
| nm-applet / blueman-applet | 网络 / 蓝牙托盘 |
| mpd | 音乐服务 |
| flameshot | 截图 |
| xfce4-notifyd | 桌面通知 |
| edid-check | 登录 10 秒后检查显示器 EDID |

## 外观

- 2px 边框：聚焦窗口是蓝色（`#5E81AC`），其他窗口是深灰，窗口贴着屏幕边缘时不画边框（`hide_edge_borders smart`）。颜色跟着配色主题走，见下面的「配色切换」
- 窗口间距 10px，工作区只有一个窗口时不留间距（`smart_gaps`）
- 标题居中，显示 mark
- 全屏时只显示属于当前全屏程序的弹窗（`popup_during_fullscreen smart`）

## 特效

### picom（自动生效，无快捷键）

配置在 `picom/.config/picom/picom.conf` 的 `rules` 里。

| 效果 | 说明 |
|---|---|
| 窗口动画 | 打开窗口时从 90% 放大并淡入，关闭时缩小并淡出。i3 切换工作区时会把旧窗口藏起来、新窗口显示出来，所以切工作区时也有这个动画 |
| 圆角 | 窗口 10px 圆角；polybar、conky、全屏窗口保持直角 |
| 失焦变暗 | 没聚焦的窗口暗 20%，浏览器、mpv、Zathura、画中画、歌词窗口不变暗 |
| 毛玻璃 | 半透明的窗口背后会模糊：rofi（85%）、通知和日历弹窗（88%）、所有浮动窗口（92%） |

想调整的话：动画快慢改 `duration`（秒），变暗程度改 `dim`，圆角改 `corner-radius`，透明度改各条规则里的 `opacity`。改完执行 `pkill picom; picom -b` 生效。

### 下拉终端 —— `Super+Enter`

按一下，从屏幕顶部滑下一个占满宽度、45% 高度的终端；再按一下滑回去。终端一直在后台运行（放在 scratchpad 里），所以命令、历史都还在。第一次按时才启动。

### 音乐频谱

- **状态栏**：polybar 中间、歌名旁边有一条 `▁▃▅▇` 频谱，跟着正在播放的声音跳动，没有声音时自动隐藏。任何程序的声音都会显示，不只是 mpd
- **大频谱窗口** —— `Super+V`，或点击状态栏上的频谱：在屏幕底部铺一条透明、无边框、220px 高的频谱，所有工作区都能看到，不会抢焦点。再按一次关闭。配色在 `cava/.config/cava/config`

### 工作区图标（自动生效）

状态栏上的工作区从 `1 2 3` 变成「数字 + 图标」，比如 `3 <火狐图标> <终端图标>`：数字后面是这个工作区里每种程序的图标。打开、关闭、移动窗口时自动更新。图标对应表在 `bin/ws-icons` 的 `ICONS` 里，没认出来的程序显示一个窗口图标。跟着你到处走的窗口（歌词、画中画）不算在内。

### 锁屏 —— `Super+Esc`，或 5 分钟无操作

背景是 `~/Pictures/lockscreen` 里随机一张 PNG；这个文件夹为空时，用当前桌面的模糊截图。中间是时钟、日期和一个圆环：打字时圆环闪青色，退格闪橙色，验证时变黄，密码错误变红。直接输入密码按 Enter 解锁。锁屏时媒体键和音量键照常可用。

没装 i3lock-color 时自动退回到普通 i3lock（只有背景图）。

### 桌面组件 —— `Super+D`

屏幕右上角的 conky：大号时钟、日期、天气（读 polybar 天气模块的缓存）、CPU / 内存 / 根分区占用、开机时长；mpd 在播放时还显示歌名、歌手和进度条。它压在所有窗口下面，只有工作区里没有窗口挡住时才看得到（开着动态壁纸时显示在视频上面）。登录时自动启动，`Super+D` 开关。配置在 `conky/.config/conky/conky.conf`。

### 动态壁纸 —— `Super+W`

把视频放进 `~/Videos/wallpapers`（mp4 / mkv / webm / mov），按 `Super+W` 随机播放一个，静音循环，铺满屏幕，在所有窗口后面。再按一次关掉，回到 nitrogen 的静态壁纸。也可以指定视频：`~/.config/i3/bin/livewall ~/Videos/xxx.mp4`。

动态壁纸会一直占用一些 GPU，打游戏前最好关掉。

### 配色切换 —— `Super+T`

在两套配色之间切换，影响 i3 边框、polybar、rofi 和 alacritty：

- **Nord**：默认配色
- **pywal**：从当前 nitrogen 壁纸里提取颜色生成一套配色

换了壁纸以后想让配色跟上，执行 `~/.config/i3/bin/theme wal`。也可以用 `theme nord` / `theme wal` 直接指定。选择会记住，下次登录自动恢复。conky、通知、电源菜单不跟着变。

## 快捷键

### 窗口焦点与移动

| 按键 | 功能 |
|---|---|
| `Alt+h/j/k/l` 或方向键 | 切换焦点 |
| `Alt+Shift+h/j/k/l` 或方向键 | 移动窗口 |
| `Alt+o` | rofi 搜索已打开的窗口并跳转 |
| `Alt+a` / `Alt+x` | 聚焦父容器 / 子容器 |
| `Alt+Space` | 在平铺和浮动窗口之间切换焦点 |
| `Alt+m` | 给窗口打一个字母 mark（再按一次取消） |
| `Alt+'` | 跳到指定 mark 的窗口 |
| `Alt+q` | 关闭窗口 |
| `Super+q`（松开时） | xkill，点击强制杀掉一个窗口 |

### 布局

| 按键 | 功能 |
|---|---|
| `Alt+;` / `Alt+v` | 下一个窗口水平 / 垂直切分 |
| `Alt+Shift+q` | 切换切分方向 |
| `Alt+s` / `Alt+w` / `Alt+e` | 堆叠 / 标签 / 切换平铺方向 |
| `Alt+f` | 全屏 |
| `Alt+Shift+Space` | 平铺 ⇄ 浮动 |
| `Alt+Shift+p` | 浮动窗口在所有工作区都显示（sticky） |
| `Alt+g` | 开关当前工作区的间距 |
| `Alt+Shift+t` | 开关 autotiling |
| `Alt+r` | 进入调整大小模式：`h/j/k/l` 或方向键调整，`Enter`/`Esc`/`Alt+r` 退出 |
| `Alt+鼠标拖动` | 移动浮动窗口 |

### 工作区

| 按键 | 功能 |
|---|---|
| `Alt+1`…`Alt+9`、`Alt+0` | 切到工作区 1–10（再按一次当前工作区的数字回到上一个） |
| `Alt+Shift+数字` | 把窗口移到该工作区 |
| `Alt+Ctrl+数字` | 把窗口移到该工作区，并跟过去 |
| `` Alt+` `` | 回到上一个工作区 |
| `Alt+[` / `Alt+]` | 上一个 / 下一个工作区 |

### Scratchpad

| 按键 | 功能 |
|---|---|
| `Alt+Shift+-` | 把窗口藏进 scratchpad |
| `Alt+-` | 呼出 / 隐藏 scratchpad 窗口 |
| `Alt+Ctrl+g` | 呼出 / 隐藏 ChatGPT（没运行就先启动） |

### 启动程序

| 按键 | 程序 |
|---|---|
| `Alt+Enter` | alacritty |
| `Alt+d` | rofi 启动器（应用 + 命令） |
| `Alt+Tab` | rofi 运行命令 |
| `Alt+c` / `Super+c` | Firefox / VS Code |
| `Alt+t` | Thunderbird |
| `Alt+z` | Zathura |
| `Alt+Shift+n` | Thunar |
| `Alt+Ctrl+o` | Obsidian |
| `Alt+Ctrl+n` | Noi |
| `Alt+Ctrl+b` | 哔哩哔哩 |
| `Alt+Ctrl+t` | Teams |
| `Alt+Ctrl+l` | LM Studio |
| `Alt+Ctrl+c` | Cursor |
| `Alt+Ctrl+d` | Double Commander |
| `Alt+Ctrl+w` | 微信（先杀掉旧进程再重新打开） |

### 截图（flameshot）

| 按键 | 功能 |
|---|---|
| `Alt+Shift+s` | 框选截图 |
| `Print` | 全屏截图，保存到 `~/Pictures` |
| `Alt+Print` | 5 秒后全屏截图，保存到 `~/Pictures` |
| `Ctrl+Print` | 全屏截图到剪贴板 |

### 音乐与媒体

| 按键 | 功能 |
|---|---|
| 媒体键 播放/下一首/上一首/停止 | 优先控制 MPRIS 播放器（playerctl），没有就控制 mpd |
| `Alt+Ctrl+p` | mpd 播放/暂停 |
| `Alt+Ctrl+←/→` | mpd 上一首 / 下一首 |
| `Super+l` | 开关浮动歌词窗口 |
| 音量键 / 静音键 / 麦克风静音键 | pactl 调音量（每次 2%） |
| 亮度键 | 通过 DDC/CI 调外接显示器亮度（ddcutil） |

### 特效（Super 键）

| 按键 | 功能 |
|---|---|
| `Super+Enter` | 下拉终端 |
| `Super+V` | 屏幕底部的音乐频谱 |
| `Super+D` | 桌面组件开关 |
| `Super+W` | 动态壁纸开关 |
| `Super+T` | 配色切换：Nord ⇄ pywal |

### 系统

| 按键 | 功能 |
|---|---|
| `Super+Esc`（松开时） | 锁屏 |
| `Alt+Ctrl+z` | rofi 电源菜单 |
| `Super+r` | 色温模式：`a` 自动、`r` 重置、`2/3/4/5` 对应 2500K–5000K |
| `Alt+p` | 重启 polybar |
| `Alt+Shift+c` | 重新加载 i3 配置 |
| `Alt+Shift+r` | 原地重启 i3（保留布局） |
| `Alt+Shift+Esc` | 退出 i3（会先确认） |
| `Alt+/` | 快捷键速查 |

## 窗口规则

**固定工作区**

| 工作区 | 程序 |
|---|---|
| 1 | LibreOffice |
| 2 | JetBrains 全家、NetBeans |
| 3 | Firefox、Edge Dev、Noi |
| 4 | 哔哩哔哩、网易云音乐、FeelUOwn |
| 5 | Steam、微信 |
| 6 | VirtualBox 虚拟机 |
| 8 | Thunderbird、QQ、Telegram、Obsidian |

**自动浮动**：对话框和弹出窗口、文件选择框（打开/保存）、pavucontrol、蓝牙管理器、网络连接编辑器、QQ、Steam、VirtualBox Manager、Lxappearance、Qalculate、Nitrogen、xdman 等。

**特殊窗口**

- 下拉终端：浮动，占满顶部，平时藏在 scratchpad
- 频谱窗口：浮动、无边框、在所有工作区显示、不抢焦点
- 画中画视频：浮动，并在所有工作区显示
- 歌词窗口：浮动、无边框、在所有工作区显示
- 日历弹窗（点击 polybar 时间）：浮动
- ChatGPT（Chromium app 模式）：启动后直接放进 scratchpad

## 状态栏（polybar）

左：工作区（带程序图标）、CPU、CPU 温度、内存、Wi-Fi
中：mpd 当前歌曲、音乐频谱、单行歌词
右：天气、音量、日期、托盘、电源菜单

- 点击歌名：rofi 搜索曲库选歌；右键歌名：重新扫描曲库，把缺的歌补回播放队列
- 点击频谱：开关屏幕底部的大频谱窗口
- 点击歌词：开关浮动歌词窗口
- 点击天气：显示详细天气
- 点击日期：弹出日历
- 点击电源图标：电源菜单

## 依赖

| 包 | 来源 | 用于 |
|---|---|---|
| cava | 官方源 | 音乐频谱 |
| conky | 官方源 | 桌面组件 |
| xwinwrap-git | 官方源 | 动态壁纸（另需 mpv） |
| i3lock-color | AUR | 带时钟的锁屏（会替换 i3lock） |
| python-pywal16 | AUR | 从壁纸取色 |
| autotiling | AUR | 自动切分方向 |
| playerctl | 官方源 | 媒体键控制浏览器等播放器 |

其他：picom v12 以上（动画需要）、python-i3ipc（工作区图标）、jq、mpv、i3、xss-lock、polybar、rofi、flameshot、nitrogen、udiskie、polkit-gnome、copyq、fcitx5、redshift、ddcutil、mpd/mpc。
