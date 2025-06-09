
#!/bin/bash
set -e

cd ~/dotfiles || exit 1

# 所有需要整理成 ~/.config 下的模块名列表（目录名 → 配置名）
modules=(i3 rofi ranger polybar picom mpv ncmpcpp mpd)

for mod in "${modules[@]}"; do
  [ -d "$mod" ] || continue

  echo "🔧 正在整理 $mod ..."

  # 创建 .config/xxx 路径
  mkdir -p "$mod/.config/$mod"

  # 移动除 .config 之外的所有一级内容进去
  find "$mod" -mindepth 1 -maxdepth 1 ! -name ".config" -exec mv {} "$mod/.config/$mod/" \;

  echo "✅ 已迁移 $mod 到 $mod/.config/$mod/"
done

echo "✨ 所有配置已整理完毕，准备好用 stow 管理了！"

