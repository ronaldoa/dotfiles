# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#ZSH_THEME="robbyrussell"
ZSH_THEME="powerlevel10k/powerlevel10k"


# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"


# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# 加载 fzf 自动补全和快捷键（Ctrl+R / Ctrl+T / Alt+C）
# `fzf --zsh` 需要 fzf ≥ 0.48，不用写死 Arch（/usr/share/fzf）或 Homebrew 的路径
command -v fzf >/dev/null && source <(fzf --zsh)
# 历史记录最大条数（内存中）
HISTSIZE=10000

# 历史文件最大条数（写入文件）
SAVEHIST=10000

# 历史文件位置
HISTFILE=~/.zsh_history

# 追加方式写入，而不是覆盖
setopt APPEND_HISTORY

# 每条命令执行完立即写入文件
setopt INC_APPEND_HISTORY

# 忽略重复命令
setopt HIST_IGNORE_ALL_DUPS

# 忽略以空格开头的命令
#setopt HIST_IGNORE_SPACE

# 合并多个 zsh 会话的历史
setopt SHARE_HISTORY


# conda / mamba, without putting either on PATH.
#
# Replaces the `conda init` + `mamba shell init` blocks that used to be here.
# Those hardcoded ~/miniforge3, so on a machine where that path is absent the
# hook failed on every shell and the fallback branch appended a non-existent
# directory to PATH. The loop below works on whichever install a machine has.
#
# Sourcing conda.sh costs ~4 ms. It defines the `conda` shell function and
# prepends <root>/condabin -- which holds the `conda` launcher and nothing else,
# no python. So `python3` still resolves to the system one and the distro
# packages the i3 scripts need (python-i3ipc, python-xlib) stay importable.
# It is `conda activate` that prepends <root>/bin, the directory that does carry
# a python; that stays opt-in per shell rather than happening in every shell:
#   conda activate <env>   enter an env      conda deactivate   leave it
#
# ~/.condarc sets auto_activate_base: false; without it base is activated
# automatically and shadows the system python again. Re-running `conda init`
# would restore the old behaviour, so don't.
for __conda_root in "$HOME/miniforge3" "$HOME/mambaforge" "$HOME/anaconda3" \
                    "$HOME/miniconda3" /opt/miniforge3 /opt/anaconda3; do
  [[ -r "$__conda_root/etc/profile.d/conda.sh" ]] || continue
  source "$__conda_root/etc/profile.d/conda.sh"
  # miniforge/mambaforge ship mamba alongside conda; anaconda does not.
  # mamba.sh expects these variables even in a fresh shell (e.g. a tmux pane).
  if [[ -r "$__conda_root/etc/profile.d/mamba.sh" && -x "$__conda_root/bin/mamba" ]]; then
    export MAMBA_EXE="$__conda_root/bin/mamba"
    export MAMBA_ROOT_PREFIX="$__conda_root"
    source "$__conda_root/etc/profile.d/mamba.sh"
  fi
  break
done
unset __conda_root

# CUDA: only where it is installed (Arch puts it in /opt/cuda; the Mac has none)
if [[ -d /opt/cuda ]]; then
  export CUDA_HOME=/opt/cuda
  export PATH=$CUDA_HOME/bin:$PATH
  export LD_LIBRARY_PATH="$CUDA_HOME/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi

export PATH="$HOME/.npm-global/bin:$PATH"

# nvm, lazily. Sourcing nvm.sh costs ~230 ms (4400 lines) and would roughly
# triple zsh startup, so only put the default version's bin on PATH here --
# that is all `node`, `npm`, `npx` and globally installed CLIs (codex, ...)
# need. The `nvm` command itself loads on first use.
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  if [[ -r "$NVM_DIR/alias/default" ]]; then
    # alias/default may hold a bare major ("20"), so glob and take the newest match.
    _nvm_bin=("$NVM_DIR/versions/node/v${$(<"$NVM_DIR/alias/default")#v}"*(/N))
    (( $#_nvm_bin )) && PATH="${_nvm_bin[-1]}/bin:$PATH"
    unset _nvm_bin
  fi
  nvm() { unfunction nvm; source "$NVM_DIR/nvm.sh"; nvm "$@"; }
fi

export EDITOR="nvim"
export VISUAL="nvim"

# OpenClaw Completion (only on machines where openclaw is installed).
# $HOME, not a hardcoded path, so this also works under another username.
if [[ -r "$HOME/.openclaw/completions/openclaw.zsh" ]]; then
  source "$HOME/.openclaw/completions/openclaw.zsh"
fi
export GOROOT="$HOME/.go"
export GOPATH="$HOME/go"
export PATH="$PATH:$GOROOT/bin:$GOPATH/bin"
# systemd 用户服务 ssh-agent 的 socket（Linux）。macOS 没有 XDG_RUNTIME_DIR，
# launchd 已经设好了 SSH_AUTH_SOCK，覆盖掉会让 ssh 找不到钥匙串里的密钥
if [[ -n $XDG_RUNTIME_DIR ]]; then
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi

# Drop duplicate PATH entries (nested shells, e.g. inside tmux, re-add them)
typeset -U path PATH
typeset -TU LD_LIBRARY_PATH ld_library_path


# MIT 6.S081 / xv6: Arch 系的 RISC-V 交叉工具链前缀是 riscv64-elf-,
# 而 xv6 的 Makefile 只自动探测 riscv64-unknown-elf- / riscv64-linux-gnu-.
export TOOLPREFIX=riscv64-elf-

# ranger: 退出后 shell 停在 ranger 里最后所在的目录;在 ranger 的子 shell(S)里再敲 ranger 就直接回去
ranger() {
    if [[ -n $RANGER_LEVEL ]]; then
        exit
    fi
    local dir_file dir
    dir_file=$(mktemp -t ranger-cd.XXXXXX)
    command ranger --choosedir="$dir_file" "$@"
    dir=$(<"$dir_file")
    rm -f -- "$dir_file"
    [[ -d $dir && $dir != $PWD ]] && cd -- "$dir"
}

# Per-machine overrides (PATH, proxies, machine-local aliases).
# Stowed from hosts/<hostname>/ by bin/dotfiles-bootstrap.
# `if` rather than `&&` so a missing file does not leave .zshrc returning 1.
if [[ -r ~/.config/dotfiles-host/zshrc ]]; then
  source ~/.config/dotfiles-host/zshrc
fi
