# 安装清单

在一台新的 Manjaro / Arch 上还原这套配置需要装的全部软件，以及装完后要做的链接和设置。
包名都按现在这台机器上实际装的核对过。

## 一、一次装完

```sh
# 官方源
sudo pacman -S --needed \
    i3-wm polybar picom rofi dunst conky xss-lock nitrogen udiskie polkit-gnome xsettingsd \
    copyq flameshot xfce4-power-manager network-manager-applet blueman redshift ddcutil \
    playerctl rofimoji libnotify lm_sensors \
    xorg-xrandr xorg-xset xorg-xrdb xorg-setxkbmap xorg-xkill \
    python python-i3ipc python-xlib jq curl psmisc iproute2 stow \
    cava xwinwrap-git mpv \
    mpd mpc ncmpcpp pipewire-pulse \
    fcitx5 fcitx5-chinese-addons fcitx5-gtk fcitx5-qt fcitx5-configtool \
    papirus-icon-theme breeze-cursors5 lxappearance \
    ttf-hack-nerd noto-fonts-cjk noto-fonts-emoji otf-font-awesome \
    alacritty wezterm zsh tmux neovim git lazygit fzf zoxide ripgrep fd nodejs npm \
    ranger ueberzugpp trash-cli bat ffmpegthumbnailer poppler 7zip unzip w3m \
    firefox thunderbird thunar zathura zathura-pdf-mupdf chromium obsidian

# AUR
yay -S --needed i3lock-color autotiling python-pywal16 nordic-theme-git visual-studio-code-bin
```

亮度脚本会自动选择后端，按硬件需要安装：

| 硬件 | 包 | 用途 |
|---|---|---|
| 外接显示器，无内置背光 | ddcutil | 亮度键通过 DDC/CI 调显示器亮度，显示器需支持 DDC/CI |
| 有内置背光的笔记本 | brightnessctl（或已有的 light） | 自动识别背光设备，按键和状态栏滚轮调节亮度 |

装完运行一次 `bin/dotfiles-bootstrap`（见第三节），最后会列出这台机器上还缺哪些包。

`i3lock-color` 会替换掉 `i3lock`，安装时提示冲突选「是」。

## 二、每个包是干什么的

### 窗口管理和桌面

| 包 | 用途 |
|---|---|
| i3-wm | 窗口管理器（`i3-input` 也在里面，mark 跳转用） |
| polybar | 状态栏 |
| picom | 合成器：动画、圆角、失焦变暗、毛玻璃（需要 v12 以上） |
| rofi | 启动器、窗口切换、快捷键速查、电源菜单、选歌 |
| rofimoji | emoji 选择器（`Super+.`） |
| dunst | 通知 |
| conky | 桌面组件、天气卡片、日历卡片（需要带 Lua + Cairo + 鼠标事件，官方源的版本就带） |
| i3lock-color（AUR） | 带时钟和输入动画的锁屏 |
| xss-lock | 无操作 / 休眠前自动锁屏 |
| autotiling（AUR） | 新窗口自动沿较长的一边切分 |
| nitrogen | 壁纸 |
| xsettingsd | 把 GTK 主题、图标、光标、字体下发给 GTK 程序 |
| polkit-gnome | 图形程序要 root 时弹出密码框 |
| udiskie | U 盘自动挂载 |
| copyq | 剪贴板历史（`Alt+Shift+V`） |
| flameshot | 截图 |
| xfce4-power-manager | 电源管理 |
| network-manager-applet、blueman | 网络 / 蓝牙托盘图标 |
| redshift | 色温（`Super+R`） |
| playerctl | 媒体键控制浏览器等播放器 |
| libnotify | `notify-send`，脚本发通知用 |
| lm_sensors | 可选的硬件传感器诊断；状态栏和桌面组件直接自动检测 sysfs |
| xorg-xrandr、xorg-xset、xorg-xrdb、xorg-setxkbmap、xorg-xkill | 设分辨率、屏保时间、配色资源、Caps/Ctrl 互换、`Super+Q` 强制关窗口 |

### 脚本依赖

| 包 | 用途 |
|---|---|
| python | 歌词、快捷键速查、工作区图标等脚本（歌词脚本只用标准库） |
| python-i3ipc | 工作区图标（`bin/ws-icons`） |
| python-xlib | 弹出卡片定位、conky 窗口层级（`bin/popup-pos`、`bin/xstack`） |
| jq | 天气、配色切换、下拉终端等脚本解析 JSON |
| curl | 天气脚本 |
| psmisc | `killall`，重启 polybar 用（一般系统自带） |
| iproute2 | `ip`，共享硬件采集器识别实际 IPv4/IPv6 路由和网卡（一般系统自带） |
| util-linux | `flock`，串行重建多屏状态栏（一般系统自带） |
| stow | `bin/dotfiles-bootstrap` 用它建立配置链接 |

硬件采集不需要按主机配置 CPU/GPU、传感器、电池或背光设备名。
NVIDIA 的利用率、温度和显存需要驱动配套的 `nvidia-smi`；AMD 使用内核接口；
Intel 等未提供的指标自动省略。采集器不会查询 runtime suspend 的独显。

修改后的桌面逻辑可离线验证：`python3 -m unittest discover -s bin/tests -v`，
测试使用模拟硬件和命令，不改变当前桌面状态。

### 特效

| 包 | 用途 |
|---|---|
| cava | 音乐频谱（状态栏和 `Super+V`） |
| xwinwrap-git、mpv | 动态壁纸（`Super+W`） |
| python-pywal16（AUR） | 从壁纸取色（`Super+T`） |

### 音乐

| 包 | 用途 |
|---|---|
| mpd、mpc、ncmpcpp | 音乐服务、命令行控制、终端播放器 |
| pipewire-pulse | 声音服务（mpd、cava、`pactl` 调音量都通过它） |

### 输入法

fcitx5、fcitx5-chinese-addons（拼音）、fcitx5-gtk、fcitx5-qt、fcitx5-configtool

### 外观

| 包 | 用途 |
|---|---|
| nordic-theme-git（AUR） | GTK 主题 |
| papirus-icon-theme | 图标（GTK 程序、rofi、通知） |
| breeze-cursors5 | 光标 |
| lxappearance | 可选：图形界面预览 GTK 主题 |
| ttf-hack-nerd | 终端、状态栏、各种图标字形 |
| noto-fonts-cjk | 中文；桌面组件、通知、rofi 的正文字体 |
| noto-fonts-emoji | emoji |
| otf-font-awesome | 状态栏的部分图标 |

### 终端和命令行

| 包 | 用途 |
|---|---|
| alacritty、wezterm | 终端 |
| zsh、tmux、neovim | shell、终端复用、编辑器 |
| git、lazygit、fzf、zoxide、ripgrep、fd、nodejs、npm | nvim 插件和日常命令行工具 |
| ranger、ueberzugpp | 文件管理器和图片预览 |
| trash-cli、bat、ffmpegthumbnailer、poppler、7zip、unzip、w3m | ranger 的回收站、代码 / 视频 / PDF / 网页预览、解压缩 |

### 常用程序（快捷键会打开它们）

firefox、thunderbird、thunar、zathura + zathura-pdf-mupdf（zathura 不装插件打不开 PDF）、chromium（ChatGPT 窗口）、obsidian（`Alt+Ctrl+O`）、visual-studio-code-bin（AUR，`Super+C`）。

Noi、LM Studio、Cursor、哔哩哔哩、Teams、Double Commander、微信是 AppImage，放在 `/mnt/data/Tools`，不用装。放在别的目录的机器，在 `hosts/<hostname>/.config/dotfiles-host/appimage.env` 里设置 `APPIMAGE_DIR`（见 `hosts/README.md`）。

## 三、链接配置

用仓库自带的脚本，它会用 stow 把所有配置链接进家目录，再叠加这台机器自己的设置（`hosts/<主机名>/`）：

```sh
cd /mnt/data/dotfiles
bin/dotfiles-bootstrap -n    # 先模拟一遍，看会建哪些链接、有没有冲突
bin/dotfiles-bootstrap       # 正式建立
bin/dotfiles-bootstrap -R    # 以后增删了文件，重新整理链接
```

脚本最后会列出这台机器上还没装的包。

**每台机器不一样的设置**放在 `hosts/<主机名>/.config/dotfiles-host/` 里（字号、亮度键、声卡等），通用配置会在最后读取它们，文件不存在就跳过。新机器先 `mkdir -p hosts/$(hostname)/.config/dotfiles-host`，具体规则见 `hosts/README.md`。

## 四、装完还要做的

- **zsh**：装 oh-my-zsh，以及主题 powerlevel10k 和插件 zsh-autosuggestions、zsh-syntax-highlighting（都是从 GitHub 克隆到 `~/.oh-my-zsh/custom/`）；`chsh -s /bin/zsh` 设为默认 shell。
- **tmux**：装 oh-my-tmux（克隆到 `~/.tmux`，再 `ln -s ~/.tmux/.tmux.conf ~/.tmux.conf`），本仓库只放 `.tmux.conf.local`。
- **通知**：屏蔽 xfce 自带的通知服务，免得它抢在 dunst 前面：`systemctl --user mask xfce4-notifyd.service`（只有装了 xfce 才需要）。
- **天气**：把 OpenWeatherMap 的 API key 写到 `~/.config/openweathermap/key`（不在仓库里）。
- **壁纸**：运行一次 `nitrogen`，选好壁纸，显示方式选 Zoomed Fill。
- **锁屏图片**（可选）：放进 `~/Pictures/lockscreen`（PNG，任何分辨率）；没有图片时用当前桌面的模糊截图。
- **动态壁纸**（可选）：视频放进 `~/Videos/wallpapers`。
- **音乐**：歌放在 `~/Music`，然后 `mpc update`。
- **显示器**：`bin/edid-check` 只对现在这台显示器有效，新机器上会提醒你处理 `/etc/X11/xorg.conf.d/20-nvidia-connected-monitor.conf`（没有这个文件就什么都不做）。

各功能的用法和快捷键见 `i3/.config/i3/README.md`。

Firefox 的视频和音频默认跟随系统输出：`wireplumber` 配置只关闭 Firefox 播放流的设备记忆，保留音量和静音记忆。修改后执行 `systemctl --user restart wireplumber`，再重新开始网页播放；之后在 pavucontrol「输出设备」中设置默认设备即可。

## Mac

Mac 上只用得到一部分（nvim、tmux、zsh、终端、ranger、mpd 等），窗口管理换成 AeroSpace。安装步骤和需要的软件见 `aerospace/.config/aerospace/README.md`。
