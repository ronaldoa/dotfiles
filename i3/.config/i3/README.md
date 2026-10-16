# i3 配置

i3 4.25（自带 gaps），Nord 配色，状态栏用 polybar。

- `Alt` = `$mod`（主修饰键），`Super` = `$mod1`
- 按 `Alt+/` 可以在 rofi 里搜索所有快捷键（`bin/keyhelp`，直接读取 i3 当前加载的配置，所以永远和实际一致）

## 目录结构

```
config              i3 主配置
bin/
  i3bar             (重)启动 polybar
  lock              i3lock 锁屏，从 ~/Pictures/lockscreen 随机选一张 PNG
  keyhelp           快捷键速查（Alt+/）
  lyrics            mpd 当前歌曲的同步歌词：状态栏单行 / 浮动歌词窗口
  music-pick        rofi 搜索 mpd 曲库并播放
  chatgpt-toggle    ChatGPT 网页放在 scratchpad 里，一键呼出/隐藏
  edid-check        登录时检查 xorg 里固定的显示器 EDID 是否还对得上
polybar/
  config            状态栏
  script/           天气、日历弹窗
```

## 开机自启

| 程序 | 作用 |
|---|---|
| xss-lock + `bin/lock` | 5 分钟无操作或休眠前锁屏 |
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

- 2px 边框：聚焦窗口是蓝色（`#5E81AC`），其他窗口是深灰，窗口贴着屏幕边缘时不画边框（`hide_edge_borders smart`）
- 窗口间距 10px，工作区只有一个窗口时不留间距（`smart_gaps`）
- 标题居中，显示 mark
- 全屏时只显示属于当前全屏程序的弹窗（`popup_during_fullscreen smart`）

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

- 画中画视频：浮动，并在所有工作区显示
- 歌词窗口：浮动、无边框、在所有工作区显示
- 日历弹窗（点击 polybar 时间）：浮动
- ChatGPT（Chromium app 模式）：启动后直接放进 scratchpad

## 状态栏（polybar）

左：工作区、CPU、CPU 温度、内存、Wi-Fi
中：mpd 当前歌曲、单行歌词
右：天气、音量、日期、托盘、电源菜单

- 点击歌名：rofi 搜索曲库选歌；右键歌名：重新扫描曲库，把缺的歌补回播放队列
- 点击歌词：开关浮动歌词窗口
- 点击天气：显示详细天气
- 点击日期：弹出日历
- 点击电源图标：电源菜单

## 依赖

需要另外安装：`playerctl`（媒体键控制浏览器等播放器）、`autotiling`（AUR）。
其余程序都已装好：i3lock、xss-lock、polybar、rofi、picom、flameshot、nitrogen、udiskie、polkit-gnome、copyq、fcitx5、redshift、ddcutil、mpd/mpc。
