#!/usr/bin/env bash

# Oh My Zsh 主题、插件与 CLI 工具配置

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

install_powerlevel10k() {
    local theme_dir="$ZSH_CUSTOM_DIR/themes/powerlevel10k"

    print_info "安装 powerlevel10k 主题..."
    if [ -d "$theme_dir" ]; then
        print_warning "powerlevel10k 已安装"
        return
    fi

    mkdir -p "$(dirname "$theme_dir")"
    git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git "$theme_dir"
    print_success "powerlevel10k 主题安装完成"
}

install_zsh_plugins() {
    local plugins_dir="$ZSH_CUSTOM_DIR/plugins"
    local plugin plugin_path

    print_info "安装 zsh 插件..."
    mkdir -p "$plugins_dir"
    for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
        plugin_path="$plugins_dir/$plugin"
        if [ -d "$plugin_path" ]; then
            print_warning "$plugin 已安装"
        else
            git clone "https://gitee.com/zsh-users/${plugin}.git" "$plugin_path"
            print_success "$plugin 安装完成"
        fi
    done
}

configure_zshrc() {
    local zshrc="$HOME/.zshrc"
    local backup

    print_info "配置 $zshrc..."
    if [ ! -f "$zshrc" ]; then
        if [ ! -f "$ZSH_DIR/templates/zshrc.zsh-template" ]; then
            print_error "找不到 Oh My Zsh 配置模板"
            return 1
        fi
        cp "$ZSH_DIR/templates/zshrc.zsh-template" "$zshrc"
    fi

    backup="${zshrc}.backup.$(date +%Y%m%d%H%M%S)"
    cp "$zshrc" "$backup"
    print_info "原配置已备份到 $backup"

    # 移除旧版脚本生成的配置和本脚本的可管理配置块。
    sed -i \
        -e '/# >>> Powerlevel10k instant prompt >>>/,/# <<< Powerlevel10k instant prompt <<</d' \
        -e '/# >>> CLI Tools environment >>>/,/# <<< CLI Tools environment <<</d' \
        -e '/# >>> CLI Tools configuration >>>/,/# <<< CLI Tools configuration <<</d' \
        -e '/^export PATH="\$HOME\/\.local\/bin:\$PATH"$/d' \
        -e '/^export PATH="\$HOME\/\.npm-global\/bin:\$PATH"$/d' \
        -e '/^export FZF_BASE="\$HOME\/\.local"$/d' \
        "$zshrc"

    sed -i '1i\
# >>> Powerlevel10k instant prompt >>>\
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then\
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"\
fi\
# <<< Powerlevel10k instant prompt <<<\
' "$zshrc"

    sed -i 's|^[[:space:]]*export ZSH=.*|export ZSH="$HOME/.oh-my-zsh"|' "$zshrc"
    sed -i 's|^[[:space:]]*ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$zshrc"
    sed -i 's|^[[:space:]]*plugins=(.*|plugins=(git zsh-autosuggestions zsh-syntax-highlighting zoxide fzf)|' "$zshrc"

    # PATH 和 fzf 环境必须在 Oh My Zsh 插件加载前生效。
    sed -i '/^[[:space:]]*source[[:space:]].*\$ZSH\/oh-my-zsh\.sh/i\
# >>> CLI Tools environment >>>\
export PATH="$HOME/.local/bin:$PATH"\
export PATH="$HOME/.npm-global/bin:$PATH"\
export FZF_BASE="$HOME/.local"\
export FZF_DEFAULT_OPTS='"'"'--height 40% --layout=reverse --border'"'"'\
# <<< CLI Tools environment <<<\
' "$zshrc"

    cat >> "$zshrc" <<'EOF'

# >>> CLI Tools configuration >>>
# zoxide - 智能目录跳转
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# eza - 现代化 ls
if command -v eza &> /dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias l='eza -l --icons --group-directories-first'
    alias ll='eza -la --icons --group-directories-first'
    alias lt='eza -l --sort=modified --icons'
    alias lS='eza -l --sort=size --icons'
    alias t='eza --tree --level=2 --icons'
    alias tt='eza --tree --level=3 --icons'
    alias ta='eza --tree --level=3 --icons --all'
fi

# bat - 现代化 cat
if command -v bat &> /dev/null; then
    alias cat='bat --paging=never'
    alias batcat='bat'
    alias bathelp='bat --plain --language=help'
    alias c='bat'
    alias cl='bat --line-range'
elif command -v batcat &> /dev/null; then
    alias cat='batcat --paging=never'
    alias bathelp='batcat --plain --language=help'
    alias c='batcat'
fi

alias ..='cd ..'
alias ...='cd ../..'
alias h='history'
alias ccc='clear'

# Powerlevel10k 用户配置
[[ ! -f "$HOME/.p10k.zsh" ]] || source "$HOME/.p10k.zsh"

# 可选的 Miniconda 安装，路径与参考配置一致。
if [ -x /opt/miniconda3/bin/conda ]; then
    __conda_setup="$(/opt/miniconda3/bin/conda shell.zsh hook 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    elif [ -f /opt/miniconda3/etc/profile.d/conda.sh ]; then
        source /opt/miniconda3/etc/profile.d/conda.sh
    else
        export PATH="/opt/miniconda3/bin:$PATH"
    fi
    unset __conda_setup
fi

ca() {
    if [ -z "$1" ]; then
        echo "Usage: ca <env_name>"
    else
        conda activate "$1"
    fi
}
# <<< CLI Tools configuration <<<
EOF

    print_success ".zshrc 配置完成"
}

echo
echo "============================================"
echo "    Oh My Zsh 配置脚本"
echo "============================================"
echo

if [ ! -d "$ZSH_DIR" ]; then
    print_error "Oh My Zsh 未安装，请先安装到 $ZSH_DIR"
    exit 1
fi

if ! command -v zsh &> /dev/null; then
    print_warning "zsh 未安装，配置已生成但暂时无法加载"
fi

install_powerlevel10k
install_zsh_plugins
configure_zshrc

echo
print_success "配置完成!"
echo "请运行 'exec zsh' 或重新打开终端。"
