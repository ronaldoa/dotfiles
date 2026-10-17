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
  xstack            按 WM_CLASS 把窗口提到最上层或压到最下层（给 conky 用）
  ws-icons          工作区名字后面显示程序图标
  dropdown          下拉终端
  cava-toggle       屏幕底部的音乐频谱窗口
  widgets           开关 conky 桌面组件
  livewall          视频动态壁纸
  theme             配色切换：Nord ⇄ pywal（从壁纸取色）
  appimage          启动 /mnt/data/Tools 里某个程序最新版本的 AppImage
  popup-pos         算出弹出卡片的位置：鼠标正下方、状态栏下面
  display           按显示器实际支持的分辨率和最高刷新率设置屏幕
themes/
  nord.Xresources   Nord 配色（theme 脚本用）
polybar/
  config            状态栏
  script/           天气、日历弹窗、频谱
```

相关的其他目录（同一个 dotfiles 仓库）：`picom/`（特效）、`cava/`（频谱配色）、`conky/`（桌面组件和弹出卡片）、`dunst/`（通知）、`rofi/`（启动器主题和电源菜单）、`gtk/`（GTK 主题、图标、光标）、`alacritty/colors.toml`（终端默认配色）。

## 开机自启

| 程序 | 作用 |
|---|---|
| xss-lock + `bin/lock` | 5 分钟无操作或休眠前锁屏 |
| `bin/theme restore` | 恢复上次选的配色（Nord / pywal） |
| `bin/ws-icons` | 工作区图标（i3 重启时自动换新的一份） |
| `bin/widgets start` | conky 桌面组件 |
| `bin/display` | 每个已连接的显示器用它的首选分辨率，并选这个分辨率支持的最高刷新率（现在这台是 2560x1440 @ 99.95Hz）；多台显示器从左到右排 |
| polkit-gnome | 图形程序要 root 时弹出密码框（pamac、gparted 等） |
| nitrogen --restore | 恢复壁纸（先运行一次 `nitrogen` 选好壁纸） |
| udiskie | U 盘自动挂载，带托盘图标 |
| autotiling | 新窗口自动沿当前窗口较长的一边切分 |
| setxkbmap | Caps Lock 和 Ctrl 互换 |
| fcitx5 | 输入法 |
| xsettingsd | 把 GTK 主题、图标、光标、字体下发给 GTK 程序 |
| xfce4-power-manager | 电源管理 |
| copyq | 剪贴板历史 |
| picom | 合成器（阴影、透明、淡入淡出） |
| polybar | 状态栏 |
| nm-applet / blueman-applet | 网络 / 蓝牙托盘 |
| mpd | 音乐服务 |
| flameshot | 截图 |
| dunst | 桌面通知（`xfce4-notifyd.service` 已用 `systemctl --user mask` 屏蔽，免得它抢先占用通知服务；想换回去就 `unmask`） |
| edid-check | 登录 10 秒后检查显示器 EDID |

## 外观

- 2px 边框：聚焦窗口是蓝色（`#5E81AC`），其他窗口是深灰，窗口贴着屏幕边缘时不画边框（`hide_edge_borders smart`）。颜色跟着配色主题走，见下面的「配色切换」
- 窗口间距 10px，工作区只有一个窗口时不留间距（`smart_gaps`）
- 标题居中，显示 mark
- 全屏时只显示属于当前全屏程序的弹窗（`popup_during_fullscreen smart`）
- 状态栏占满屏幕宽度，离屏幕上边缘 3px，和下面的窗口之间留 10px（和窗口之间的间距一样）
- 启动器、电源菜单、通知、桌面组件、天气和日历卡片都是同一种深色圆角卡片

### rofi（启动器）

`Alt+D`、`Alt+O`、`Alt+Tab`、`Alt+/` 打开的都是屏幕中间的深色圆角卡片：顶部是搜索框，下面是带图标的列表（Papirus-Dark 图标），底部可以切换模式。主题在 `rofi/.config/rofi/themes/card.rasi`，颜色在 `themes/colors.rasi`（切到 pywal 时只替换颜色）。

**电源菜单**（`Alt+Ctrl+Z` 或点状态栏电源图标）：一排五个大按钮——锁屏、睡眠、注销、重启、关机。用方向键或鼠标选择，除了锁屏都会再弹出「Yes / No」两个按钮确认。

### 通知（dunst）

右上角、状态栏下方的深色圆角卡片，左边是程序图标，上面一行小字是程序名，下面是标题和正文；音量这类带进度的通知会显示进度条。紧急通知有红色边框，而且不会自动消失。

- 左键：执行通知的默认动作并关掉它；右键：关掉；中键：全部关掉
- `Super+N`：重新显示最近一条通知（可以连按往回翻，最多保留 30 条）
- `Super+Shift+N`：关掉所有通知

配置在 `dunst/.config/dunst/dunstrc`。

### GTK 程序

Thunar、pavucontrol、文件选择框这类 GTK 程序统一用 Nordic 主题、Papirus-Dark 图标、Breeze 光标和 Noto Sans CJK 字体。登录时由 xsettingsd 下发，改 `~/.config/xsettingsd/xsettingsd.conf` 后执行 `pkill -HUP xsettingsd`，已经打开的程序会马上换。`gtk-3.0/settings.ini`、`gtk-4.0/settings.ini` 和 `~/.gtkrc-2.0` 里是同样的设置，作为 xsettingsd 没运行时的备用。使用 libadwaita 的新版 GNOME 程序不认主题，只会跟着切到深色。

## 特效

### picom（自动生效，无快捷键）

配置在 `picom/.config/picom/picom.conf` 的 `rules` 里。

| 效果 | 说明 |
|---|---|
| 窗口动画 | 打开窗口时从 90% 放大并淡入，关闭时缩小并淡出。i3 切换工作区时会把旧窗口藏起来、新窗口显示出来，所以切工作区时也有这个动画 |
| 圆角 | 窗口 10px 圆角；polybar、conky、全屏窗口保持直角 |
| 失焦变暗 | 没聚焦的窗口暗 20%，浏览器、mpv、Zathura、画中画、歌词窗口不变暗 |
| 毛玻璃 | 半透明的窗口背后会模糊：rofi（92%，18px 圆角）、所有浮动窗口（92%）。通知、桌面组件、弹出卡片自己画圆角，所以不加模糊和阴影 |

想调整的话：动画快慢改 `duration`（秒），变暗程度改 `dim`，圆角改 `corner-radius`，透明度改各条规则里的 `opacity`。改完执行 `pkill picom; picom -b` 生效。

### 下拉终端 —— `Super+Enter`

按一下，从状态栏下方滑下一个占满宽度、45% 高度的终端；再按一下滑回去。终端一直在后台运行（放在 scratchpad 里），所以命令、历史都还在。第一次按时才启动。

### 音乐频谱

- **状态栏**：polybar 中间、歌名旁边有一条 `▁▃▅▇` 频谱，跟着正在播放的声音跳动，没有声音时自动隐藏。任何程序的声音都会显示，不只是 mpd
- **大频谱窗口** —— `Super+V`，或点击状态栏上的频谱：在屏幕底部铺一条透明、无边框、220px 高的频谱，所有工作区都能看到，不会抢焦点。再按一次关闭。配色在 `cava/.config/cava/config`

### 工作区图标（自动生效）

状态栏上的工作区从 `1 2 3` 变成「数字 + 图标」，比如 `3 <火狐图标> <终端图标>`：数字后面是这个工作区里每种程序的图标。打开、关闭、移动窗口时自动更新。图标对应表在 `bin/ws-icons` 的 `ICONS` 里，没认出来的程序显示一个窗口图标。跟着你到处走的窗口（歌词、画中画）不算在内。

### 锁屏 —— `Super+Esc`，或 5 分钟无操作

背景是 `~/Pictures/lockscreen` 里随机一张 PNG，等比缩放铺满屏幕（任何分辨率的图都行）；这个文件夹为空时，用当前桌面的模糊截图。中间是时钟、日期和一个圆环：打字时圆环闪青色，退格闪橙色，验证时变黄，密码错误变红。直接输入密码按 Enter 解锁。锁屏时媒体键和音量键照常可用。

没装 i3lock-color 时自动退回到普通 i3lock（只有背景图）。

### 桌面组件 —— `Super+D`

屏幕右上角一组 Apple 风格的小组件：深色半透明圆角卡片，2×2 网格加底部一张宽卡片，全英文：

| 卡片 | 内容 |
|---|---|
| Clock | 星期、时间、日期、第几周 / 一年中第几天 |
| Weather | 城市、天气图标、温度、天气、最高 / 最低温、湿度、风速（读 polybar 天气模块的缓存，10 分钟更新一次） |
| System | 开机时长；CPU 占用和温度、内存、根分区，各带一条进度条 |
| Network | IP、下载 / 上传速度、最近 40 秒的下载速度曲线 |
| Now Playing | mpd 当前歌曲、歌手、播放进度；暂停时显示 PAUSED，没在放时显示 Not Playing |

它压在所有窗口下面，只有工作区里没有窗口挡住时才看得到（开着动态壁纸时显示在视频上面）。登录时自动启动，`Super+D` 开关。

卡片全部用 Lua + Cairo 画在 `conky/.config/conky/widgets.lua` 里（画圆角卡片、文字、进度条的工具函数和配色在 `lib.lua`，天气和日历弹出卡片也用它）：卡片大小在 `widgets.lua` 开头（`CARD`），圆角和颜色在 `lib.lua` 开头（`RADIUS`、`BG` 等）。网络卡片自动用默认路由所在的网卡。`conky.conf` 只负责窗口位置和大小。

### 动态壁纸 —— `Super+W`

把视频放进 `~/Videos/wallpapers`（mp4 / mkv / webm / mov），按 `Super+W` 随机播放一个，静音循环，铺满屏幕，在所有窗口后面。再按一次关掉，回到 nitrogen 的静态壁纸。也可以指定视频：`~/.config/i3/bin/livewall ~/Videos/xxx.mp4`。

动态壁纸会一直占用一些 GPU，打游戏前最好关掉。

### 配色切换 —— `Super+T`

在两套配色之间切换，影响 i3 边框、polybar、rofi 和 alacritty：

- **Nord**：默认配色
- **pywal**：从当前 nitrogen 壁纸里提取颜色生成一套配色

换了壁纸以后想让配色跟上，执行 `~/.config/i3/bin/theme wal`。也可以用 `theme nord` / `theme wal` 直接指定。选择会记住，下次登录自动恢复。rofi 的启动器和电源菜单都跟着变；conky 卡片、通知、GTK 程序不跟着变。

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

Noi、哔哩哔哩、Teams、LM Studio、Cursor、Double Commander、微信都是 `/mnt/data/Tools` 里的 AppImage，由 `bin/appimage` 按文件名前缀找版本号最大的那个来启动。下载新版本后直接放进去就行，不用改配置；旧版本可以删掉，也可以留着。

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

### 剪贴板、emoji、通知

| 按键 | 功能 |
|---|---|
| `Alt+Shift+V` | 剪贴板历史（copyq），选中一条再粘贴 |
| `Super+.` | emoji 和符号选择器（rofimoji），可以用英文名搜索，选中后复制到剪贴板 |
| `Super+N` | 重新显示最近一条通知 |
| `Super+Shift+N` | 关掉所有通知 |

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

- 下拉终端：浮动，在状态栏下方，平时藏在 scratchpad
- copyq 剪贴板窗口：浮动，屏幕居中
- 频谱窗口：浮动、无边框、在所有工作区显示、不抢焦点
- 画中画视频：浮动，并在所有工作区显示
- 歌词窗口：浮动、无边框、在所有工作区显示
- ChatGPT（Chromium app 模式）：启动后直接放进 scratchpad

## 状态栏（polybar）

左：工作区（带程序图标）、CPU、CPU 温度、内存、Wi-Fi
中：mpd 当前歌曲、音乐频谱、单行歌词
右：天气、音量、日期、托盘、电源菜单

- 点击歌名：rofi 搜索曲库选歌；右键歌名：重新扫描曲库，把缺的歌补回播放队列
- 点击频谱：开关屏幕底部的大频谱窗口
- 点击歌词：开关浮动歌词窗口
- 点击天气：弹出 / 关闭天气卡片（和桌面组件同一种风格）：当前温度、体感、最高 / 最低温，湿度、风速、日出日落，以及未来 24 小时每 3 小时一格的预报（含降水概率）。卡片画在 `conky/.config/conky/weather-popup.lua` 里
- 点击日期：弹出 / 关闭日历卡片：左边是今天（星期、日期、第几周、今年第几天和剩余天数），右边是月历（周一开头，今天用红圈标出，周末字色较淡）。点右上角的 ‹ › 或在卡片上滚动鼠标滚轮可以看上个月 / 下个月，点月份名字回到本月。卡片画在 `conky/.config/conky/calendar-popup.lua` 里
- 点击电源图标：电源菜单
- 天气和日历卡片会出现在鼠标点击位置的正下方（`bin/popup-pos`），所以状态栏右边增减模块后也能对准

## 换显示器

和屏幕有关的设置都是按实际情况算出来的，换一台显示器（比如 24 寸 1080p）不用改配置：

- 分辨率和刷新率：`bin/display` 登录时自动选
- 状态栏占满宽度；下拉终端、频谱窗口、天气和日历卡片都按当前屏幕的可用区域定位
- 锁屏图片自动缩放铺满
- 桌面组件和弹出卡片：conky 会按屏幕 DPI 调整窗口大小；窗口比卡片小时，卡片整体等比缩小，不会被裁掉
- 网卡名自动识别（polybar 取第一个无线网卡，桌面组件取默认路由的网卡）

唯一和这台显示器绑定的是 `bin/edid-check`：它检查 `/etc/X11/xorg.conf.d/20-nvidia-connected-monitor.conf` 里固定的 EDID（用来解决 HDMI 显示器断电后黑屏）。换显示器后登录会弹通知提醒，那时要按通知里的提示重新生成那个文件，或者删掉它。

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
| xsettingsd | 官方源 | 把 GTK 主题设置下发给 GTK 程序 |
| nordic-theme | AUR | GTK 主题 |
| rofimoji | 官方源 | emoji 选择器 |

其他：picom v12 以上（动画需要）、python-i3ipc（工作区图标）、jq、mpv、i3、xss-lock、polybar、rofi、flameshot、nitrogen、udiskie、polkit-gnome、copyq、dunst、papirus-icon-theme、breeze（光标）、python-xlib、fcitx5、redshift、ddcutil、mpd/mpc。
