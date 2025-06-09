#!/bin/bash

set -e

echo "📦 正在安装 oh-my-zsh ..."
# 安装 oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "✅ oh-my-zsh 已存在，跳过安装"
fi

echo "🎨 安装 Powerlevel10k 主题 ..."
# 安装 Powerlevel10k
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    ~/.oh-my-zsh/custom/themes/powerlevel10k
else
  echo "✅ Powerlevel10k 已存在，跳过安装"
fi

echo "🔠 安装 Nerd Font（Hack）..."
yay -S --noconfirm nerd-fonts-hack || {
  echo "⚠️ Nerd Font 安装失败，请手动检查 yay 是否安装"
}

echo "🔗 软链接 dotfiles 配置文件 ..."

# tmux
ln -sf ~/dotfiles/tmux/tmux.conf.local ~/.tmux.conf.local

# wezterm
ln -sf ~/dotfiles/wezterm/wezterm.lua ~/.wezterm.lua

# zsh
ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/dotfiles/zsh/.p10k.zsh ~/.p10k.zsh

# nvim
mkdir -p ~/.config/nvim
ln -sf ~/dotfiles/nvim/init.lua ~/.config/nvim/init.lua

echo "✅ 配置已完成！重新加载 zsh..."

# 重新加载 zsh 并启动 p10k 向导（首次）
exec zsh -c "source ~/.zshrc && p10k configure"

