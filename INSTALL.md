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
    firefox thunderbird thunar zathura zathura-pdf-mupdf chromium obsidian obs-studio

# AUR
yay -S --needed i3lock-color autotiling python-pywal16 nordic-theme-git visual-studio-code-bin skippy-xd-git

# 命令行工具（每个是干什么的见第二节「命令行工具」；和上面重复的包 --needed 会跳过）
sudo pacman -S --needed \
    fzf ripgrep fd bat eza zoxide atuin direnv \
    git-delta difftastic lazygit github-cli git-lfs \
    jq go-yq sd xh wget aria2 rsync \
    btop htop duf dust ncdu nethogs fastfetch inxi \
    tldr shellcheck actionlint hyperfine watchexec tokei cloc \
    yazi glow chafa lnav tree trash-cli 7zip unzip unrar \
    yt-dlp ffmpeg task urlscan micro xclip
yay -S --needed lux-dl                              # 在 archlinuxcn 源里
curl -LsSf https://astral.sh/uv/install.sh | sh     # uv 用官方脚本装到 ~/.local/bin，之后 `uv self update` 升级

# 同步、远程、文档和视频（装完的设置见第四节）
sudo pacman -S --needed syncthing tailscale kdeconnect xournalpp pdfarranger kdenlive
yay -S --needed zotero-bin                          # archlinuxcn 源或 AUR
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
| skippy-xd-git（AUR） | 窗口总览（`Super+Tab`） |
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

### 命令行工具

第一节里「命令行工具」那条命令装的全部工具。

**找文件、跳目录、看内容**

| 包 | 命令 | 干什么的 |
|---|---|---|
| fzf | `fzf` | 模糊查找：zsh 里 `Ctrl+T` 选文件、`Alt+C` 进目录；nvim 也用它 |
| ripgrep | `rg` | 在文件内容里搜索，比 grep 快，自动跳过 .gitignore 里的文件 |
| fd | `fd` | 按文件名找文件，比 find 好写 |
| bat | `bat` | 带语法高亮和行号的 `cat`；ranger 也用它预览代码 |
| eza | `eza` | 带图标、git 状态、树形视图（`eza -T`）的 `ls` |
| zoxide | `z`、`zi` | 记住常去的目录，`z dot` 直接跳到 dotfiles，`zi` 用 fzf 选；yazi 里的 `z` 也用它 |
| atuin | `atuin` | 命令历史：`Ctrl+R` 全文搜索，可按目录 / 主机过滤，可多台机器同步 |
| direnv | `direnv` | 进目录时自动加载该目录 `.envrc` 里的环境变量 / 虚拟环境，离开时撤掉 |
| yazi | `yazi` | 终端文件管理器，带图片预览（ranger 的现代替代） |
| tree | `tree` | 树形列出目录 |
| trash-cli | `trash-put` | 删到回收站而不是直接删掉；ranger 的删除也用它 |

**git**

| 包 | 命令 | 干什么的 |
|---|---|---|
| git-delta | `delta` | 带语法高亮、并排显示的 git diff |
| difftastic | `difft` | 按语法结构比较差异：只改了缩进或换行时不会整段标红 |
| lazygit | `lazygit` | git 的终端界面：暂存、提交、rebase、解冲突 |
| github-cli | `gh` | 在命令行里看 / 开 PR 和 issue、克隆仓库 |
| git-lfs | `git lfs` | 大文件（模型、素材）存进 git |

**处理数据和网络**

| 包 | 命令 | 干什么的 |
|---|---|---|
| jq | `jq` | 处理 JSON；天气、配色等脚本也用它 |
| go-yq | `yq` | 处理 YAML / TOML / XML，用法同 jq |
| sd | `sd` | 查找替换，比 sed 好写（`sd 旧 新 文件`） |
| xh | `xh` | 发 HTTP 请求，输出带颜色，比 curl 好读 |
| wget | `wget` | 下载文件 |
| aria2 | `aria2c` | 多线程 / 断点续传下载，支持 BT 和磁力链接 |
| rsync | `rsync` | 增量同步 / 备份文件，可以走 ssh |

**看系统状态**

| 包 | 命令 | 干什么的 |
|---|---|---|
| btop | `btop` | 图形化的 CPU、内存、磁盘、网络、进程监控 |
| htop | `htop` | 轻量的进程监控 |
| duf | `duf` | 各分区用了多少，比 df 直观 |
| dust | `dust` | 哪个目录占空间最多，一眼看出来 |
| ncdu | `ncdu` | 交互式翻目录、清理大文件 |
| nethogs | `nethogs` | 哪个进程在占网速（要 sudo） |
| fastfetch | `fastfetch` | 显示系统信息和发行版 logo |
| inxi | `inxi -F` | 详细硬件信息，报 bug 时贴给别人看 |

**写脚本和代码**

| 包 | 命令 | 干什么的 |
|---|---|---|
| tldr | `tldr` | 命令的常用示例，比 man 短（`tldr tar`） |
| shellcheck | `shellcheck` | 检查 shell 脚本的常见错误（引号、未定义变量等） |
| actionlint | `actionlint` | 检查 GitHub Actions 的 workflow 文件 |
| hyperfine | `hyperfine` | 反复运行命令、统计耗时，对比两种写法哪个快 |
| watchexec | `watchexec` | 文件一改就自动重跑命令（`watchexec -e py pytest`） |
| tokei、cloc | `tokei`、`cloc` | 按语言统计代码行数 |
| uv（官方脚本） | `uv` | Python 包和虚拟环境管理，比 pip 快很多 |

**预览、日志、媒体和其他**

| 包 | 命令 | 干什么的 |
|---|---|---|
| glow | `glow` | 在终端里渲染 Markdown（`glow README.md`） |
| chafa | `chafa` | 在终端里显示图片 |
| lnav | `lnav` | 看日志：自动高亮、按时间合并多个日志、过滤 |
| 7zip、unzip、unrar | `7z`、`unzip`、`unrar` | 解压缩各种格式 |
| yt-dlp | `yt-dlp` | 下载 YouTube 等网站的视频 / 音频 |
| lux-dl（archlinuxcn） | `lux` | 下载哔哩哔哩等国内网站的视频 |
| ffmpeg | `ffmpeg` | 音视频转码、剪切、提取音轨 |
| task | `task` | Taskwarrior，命令行待办清单 |
| urlscan | `urlscan` | 从一段文字（邮件、日志）里挑出链接打开 |
| micro | `micro` | 操作像普通编辑器的终端编辑器（`Ctrl+S` 保存），临时改文件用 |
| xclip | `xclip` | 命令行读写剪贴板（`… \| xclip -sel c`） |

### 同步、远程、文档和视频

| 包 | 干什么的 |
|---|---|
| syncthing | 几台机器之间自动同步文件夹，点对点直传、不经过云端；在浏览器里 `http://127.0.0.1:8384` 设置 |
| tailscale | 把自己的几台机器连成一个私有网络，在外面也能用 `ssh <机器名>` 连回家里的台式机 |
| kdeconnect | 手机和电脑互通：手机通知显示在电脑上、共享剪贴板、互传文件、手机当遥控器；托盘图标随 i3 启动 |
| xournalpp | Xournal++：在 PDF 上手写 / 打字批注、签名，记手写笔记 |
| pdfarranger | 合并、拆分、旋转、删除、重排 PDF 页面 |
| kdenlive | 视频剪辑（剪 OBS 录的视频） |
| zotero-bin | Zotero：管理论文和参考文献，浏览器一键收藏，在 LibreOffice / Word 里插入引用 |

### 常用程序（快捷键会打开它们）

firefox、thunderbird、thunar、zathura + zathura-pdf-mupdf（zathura 不装插件打不开 PDF）、chromium（ChatGPT 窗口）、obsidian（`Alt+Ctrl+O`）、obs-studio（`Alt+Ctrl+R`）、visual-studio-code-bin（AUR，`Alt+Ctrl+C`）。

Noi、LM Studio、哔哩哔哩、Teams、Double Commander、微信是 AppImage，放在 `/mnt/data/Tools`，不用装。Double Commander 也可以用 pacman 装（`doublecmd-qt5` 或 `doublecmd-qt6`），装了以后 `Alt+Ctrl+D` 优先用它。放在别的目录的机器，在 `hosts/<hostname>/.config/dotfiles-host/appimage.env` 里设置 `APPIMAGE_DIR`（见 `hosts/README.md`）。i3 启动时 `bin/appimage-menu` 会给它们生成菜单项，不需要 AppImageLauncher。

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
- **锁屏图片**（可选）：装了 i3lock-color 时锁屏背景是当前屏幕的模糊截图，用不到图片；只有普通 i3lock 时才用 `~/Pictures/lockscreen` 里的 PNG（要和屏幕分辨率一样），没有就用 nitrogen 当前的桌面壁纸。
- **动态壁纸**（可选）：视频放进 `~/Videos/wallpapers`。
- **音乐**：歌放在 `~/Music`，然后 `mpc update`。
- **Syncthing**：`systemctl --user enable --now syncthing`（开机自动运行），再到 `http://127.0.0.1:8384` 添加其他机器和要同步的文件夹，步骤见文末「Syncthing 在两台机器之间同步」。
- **Tailscale**：`sudo systemctl enable --now tailscaled`，`sudo tailscale up` 后按提示在浏览器里登录；`sudo tailscale set --operator=$USER` 之后不用 sudo 也能用 `tailscale` 命令。
- **防火墙**（开了 ufw 才需要）：KDE Connect 要 `sudo ufw allow 1714:1764/udp` 和 `sudo ufw allow 1714:1764/tcp`；Syncthing 要 `sudo ufw allow syncthing`，局域网里才能直连。
- **KDE Connect**：手机装 KDE Connect（安卓在应用商店 / F-Droid，iPhone 在 App Store），和电脑连同一个网络，在托盘图标里配对。
- **Caps 和 Ctrl 互换**：i3 启动时跑的 `setxkbmap -option ctrl:swapcaps` 只管当时插着的键盘，键盘拔插、休眠唤醒、USB 掉线后就失效了。
  写进系统的键盘配置（`/etc/X11/xorg.conf.d/00-keyboard.conf`），之后接上的键盘也都会换，重新登录后生效：
  `sudo localectl set-x11-keymap cn pc105 "" ctrl:swapcaps,terminate:ctrl_alt_bksp`（布局按这台机器改，`setxkbmap -query` 查）。
- **显示器**：`bin/edid-check` 只对现在这台显示器有效，新机器上会提醒你处理 `/etc/X11/xorg.conf.d/20-nvidia-connected-monitor.conf`（没有这个文件就什么都不做）。

各功能的用法和快捷键见 `i3/.config/i3/README.md`。

Firefox 的视频和音频默认跟随系统输出：`wireplumber` 配置只关闭 Firefox 播放流的设备记忆，保留音量和静音记忆。修改后执行 `systemctl --user restart wireplumber`，再重新开始网页播放；之后在 pavucontrol「输出设备」中设置默认设备即可。

## 五、远端更新后让它生效

```sh
git pull
git log --stat ORIG_HEAD..HEAD   # 看这次改了哪些包
bin/dotfiles-bootstrap -n        # 只在增删、改名了文件时需要：先模拟
bin/dotfiles-bootstrap -R        # 再重新整理链接
```

配置是链接进家目录的，只改了已有文件的内容时，`git pull` 完文件就已经是新的了，不用跑 bootstrap。
新加了包或 `hosts/<主机名>/` 下的文件也要 `-R`；新配置用到了没装的程序，bootstrap 最后会列出来。

剩下的是让正在运行的程序重新读配置：

| 改了 | 怎么生效 |
|---|---|
| i3 | `i3 -C -c ~/.config/i3/config` 检查语法，再 `Alt+Shift+c`（`i3-msg reload`）；改了 `exec` 启动项要 `Alt+Shift+r` |
| polybar（`i3/.config/i3/polybar`） | `Alt+p`（`~/.config/i3/bin/polybar-launch`，每块屏幕重建一条） |
| picom | 一般会自己重新读；不行就 `pkill -x picom; ~/.config/i3/bin/compositor -b` |
| dunst | `dunstctl reload` |
| conky 桌面组件 | `~/.config/i3/bin/widgets stop; ~/.config/i3/bin/widgets start` |
| wireplumber | `systemctl --user restart wireplumber` |
| zsh | `exec zsh` |
| tmux | `tmux source ~/.tmux.conf` |
| nvim | 重开；`lazy-lock.json` 变了就 `:Lazy restore` |
| alacritty、ranger、rofi 等 | 自动生效或下次打开生效 |
| aerospace（Mac） | `aerospace reload-config` |

## Mac

Mac 上只用得到一部分：aerospace、alacritty、conda、mpd、ncmpcpp、nvim、ranger、tmux、wallpapers、wezterm、zsh。
`bin/dotfiles-bootstrap` 在 macOS 上会自动跳过 i3、picom、rofi 这些 Linux 专用的包（列表在脚本的 `LINUX_ONLY`），用法和 Linux 一样：

```sh
brew install stow mpd mpc ncmpcpp fzf chafa neovim tmux ranger
brew install --cask alacritty
bin/dotfiles-bootstrap -n     # 先看看会链接什么；已有的同名文件要先挪走，stow 不会覆盖
bin/dotfiles-bootstrap
brew services start mpd       # Homebrew 的 mpd 读 ~/.mpdconf
```

**KDE Connect**（可选，和 Linux 机器互传文件、共享剪贴板）：Homebrew 里没有，到 <https://kdeconnect.kde.org/download.html> 下载 macOS 版，
拖进「应用程序」；第一次打开时在「系统设置 → 隐私与安全性」里允许运行，再在菜单栏图标里和 Linux 机器配对（两边要在同一个网络）。
iPhone 用 App Store 里的 KDE Connect，但 iOS 不让它读通知、自动同步剪贴板，切到后台会断开，只适合传文件和当遥控器。

**Syncthing**：`brew install --cask syncthing-app`（带菜单栏图标，开机自动启动；点图标选 Open 打开设置网页）。
不要菜单栏图标就用命令行版：`brew install syncthing`，再 `brew services start syncthing`。和 Linux 机器配对见下一节。

本机设置在 `hosts/QingyuZhoudeMacBook-Pro/`（mpd 用 osx 输出、alacritty 字号和 Cmd 快捷键、zshrc）。
窗口管理换成 AeroSpace，需要的软件和 macOS 设置见 `aerospace/.config/aerospace/README.md`。

## Syncthing 在两台机器之间同步

Linux 和 Mac、两台 Linux 之间都一样。两边先都装好 Syncthing 并运行，设置网页都是 `http://127.0.0.1:8384`。

1. **互相添加设备**：在一台机器上运行 `syncthing device-id` 查看它的设备 ID（网页右上角「操作 → 显示 ID」也能看到）。
   到另一台的网页点右下角「添加远程设备」，粘贴这个 ID、起个名字保存；
   原来那台的网页顶部会弹出「新设备请求连接」，点「添加设备」。同一个局域网里几秒钟就能互相发现。
2. **共享文件夹**：在一边点「添加文件夹」选好目录，到「共享」标签页勾选另一台设备，保存；
   另一边会弹出「共享文件夹请求」，点「添加」并选好在这台机器上放到哪个目录。之后任何一边改了文件都会自动同步。
3. **不在同一个网络时**：默认经公共中继服务器连接，能连上但比较慢。两边都登录了 Tailscale 的话，
   在网页里编辑对方这个设备，「高级」里把地址设成 `tcp://<对方的 Tailscale IP>:22000, dynamic`（IP 用 `tailscale ip -4` 查），在外面也能直连。

注意：

- 不要同步 git 仓库或 `.git` 目录，两边同时改动容易出冲突文件；dotfiles 这类仓库继续用 git 推拉。
- 不想同步的缓存、`node_modules` 等，在文件夹的「忽略模式」里加规则。
- 两边同时改了同一个文件时不会覆盖，而是多出一份 `.sync-conflict-…` 文件，自己决定留哪个。

## 从外面 ssh 回家里的电脑

前提：两台机器都装了 Tailscale 并登录同一个账号（见第四节）；被连的机器不能睡眠，xfce4-power-manager 里把「空闲时睡眠」关掉或设长一点。

**办法一：Tailscale SSH（推荐）**。由 Tailscale 验证身份，不用开 sshd，也不用管密钥和密码，只有登录了自己账号的设备能连。在被连的机器上：

```sh
sudo tailscale set --ssh
sudo ufw allow in on tailscale0      # 开了 ufw 才需要：放行 Tailscale 网络进来的连接，外网照样挡住
```

然后在另一台（比如 Mac：`brew install --cask tailscale` 或 App Store 装 Tailscale）上直接 `ssh <用户名>@<机器名>`，
例如 `ssh ronaldo@ronaldo-ms7c94`。机器名就是 Tailscale 里显示的名字（`tailscale status` 查），在家在外面都能用；第一次可能要在浏览器里确认一次。

**办法二：普通 OpenSSH**。要给不支持 Tailscale SSH 的工具用时（某些 IDE 的远程开发、手机 ssh App）：

```sh
sudo systemctl enable --now sshd
sudo ufw allow in on tailscale0 to any port 22    # 只允许经 Tailscale 连 22 端口
```

再把另一台的公钥（`~/.ssh/id_ed25519.pub`）追加到这台的 `~/.ssh/authorized_keys`，最好在 `/etc/ssh/sshd_config` 里设 `PasswordAuthentication no`，只允许密钥登录。

**起个短名字**：在发起连接那台的 `~/.ssh/config` 里加上，之后 `ssh home` 就能连：

```
Host home
    HostName ronaldo-ms7c94
    User ronaldo
```

**在家里的局域网里**：同样用 `ssh ronaldo@ronaldo-ms7c94`。两台在同一个局域网时 Tailscale 会直接在局域网里连，不绕外网，速度和局域网直连差不多；
`tailscale ping ronaldo-ms7c94` 显示 `direct` 就是直连，显示 `via DERP` 是走了 Tailscale 的中转服务器。
要用机器名或 `100.x` 地址连，不要用 `192.168.x.x` 这种局域网 IP：Tailscale SSH 只接受经 Tailscale 进来的连接，办法二的 ufw 规则也只放行 `tailscale0`。
局域网里没装 Tailscale 的设备也要连的话，用办法二，再放行局域网网段（按自家网段改）：

```sh
sudo ufw allow from 192.168.1.0/24 to any port 22
```

**在学校或其他网络**：命令完全一样。注意：

- 校园网常常限制 UDP，打不通直连时会走中转服务器（`via DERP`），能连上，只是延迟高一点，传大文件会慢。
- 发起连接那台要自己能装 Tailscale（需要管理员权限）；学校机房、实验室的公用机一般装不了，也不要在公用机上登录自己的账号。
- 连不上时，先在发起连接那台跑 `tailscale status`，看家里那台是不是在线。

**接着用家里的 tmux**：tmux 会话一直在家里那台上跑，ssh 断了也不会退出，连上后 attach 就能接着做：

```sh
ssh home
tmux ls               # 看有哪些会话
tmux attach -t 0      # 接上会话 0；一步到位：ssh -t home tmux attach -t 0
```

- 家里屏幕上那个 tmux 还接着时，两边显示同一个画面，窗口大小跟最后操作的那一边走；`tmux attach -d -t 0` 会把其他客户端断开。回家后再 attach 一次就恢复了。
- 网断了、笔记本合上都没关系，程序还在家里跑，重新 ssh 再 attach 就行。
- 家里那台重启或关机后会话就没了（`.tmux.conf.local` 里 tmux-resurrect / continuum 是注释掉的）。
- 颜色乱或报 `unknown terminal`：发起连接那台的终端设了家里不认识的 `TERM`（如 Ghostty、kitty），用 `TERM=xterm-256color ssh home`。
