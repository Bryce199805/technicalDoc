#!/bin/bash

# ============================================
# Oh My Zsh 配置脚本
# 安装主题、插件并配置 .zshrc
# ============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ============================================
# 安装 powerlevel10k 主题
# ============================================
install_powerlevel10k() {
    print_info "安装 powerlevel10k 主题..."
    local theme_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

    if [ -d "$theme_dir" ]; then
        print_warning "powerlevel10k 已安装"
    else
        mkdir -p "$(dirname "$theme_dir")"
        git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git "$theme_dir"
        print_success "powerlevel10k 主题安装完成"
    fi
}

# ============================================
# 安装 zsh 插件
# ============================================
install_zsh_plugins() {
    print_info "安装 zsh 插件..."
    local plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

    # Gitee 镜像的插件
    for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
        local plugin_path="$plugins_dir/$plugin"
        if [ -d "$plugin_path" ]; then
            print_warning "$plugin 已安装"
        else
            git clone "https://gitee.com/zsh-users/${plugin}.git" "$plugin_path"
            print_success "$plugin 安装完成"
        fi
    done
}

# ============================================
# 配置 .zshrc
# ============================================
configure_zshrc() {
    print_info "配置 .zshrc..."

    local zshrc="$HOME/.zshrc"

    # 如果没有 .zshrc，从模板创建
    if [ ! -f "$zshrc" ]; then
        if [ -f "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" ]; then
            cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$zshrc"
        else
            # 创建最小配置
            cat > "$zshrc" << 'ZSHRC_BASE'
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zoxide fzf)

source $ZSH/oh-my-zsh.sh
ZSHRC_BASE
        fi
    fi

    # 备份原配置
    cp "$zshrc" "${zshrc}.backup.$(date +%Y%m%d%H%M%S)"

    # 设置主题
    sed -i 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$zshrc"

    # 设置插件
    sed -i 's/plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zoxide fzf)/' "$zshrc"

    # 检查是否已有配置块
    if grep -q "# ========== CLI Tools Aliases" "$zshrc" 2>/dev/null; then
        print_warning ".zshrc 已包含 CLI Tools 配置，跳过"
        return
    fi

    # 添加完整配置
    cat >> "$zshrc" << 'EOF'

# ========== 现代工具别名 ==========
# zoxide - 智能目录跳转（替代 cd）
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# fzf - 模糊搜索配置
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

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
    alias bathelp='bat --plain --language=help'
elif command -v batcat &> /dev/null; then
    alias cat='batcat --paging=never'
    alias bathelp='batcat --plain --language=help'
fi

# System aliases
alias ..='cd ..'
alias ...='cd ../..'
alias h='history'
alias ccc='clear'

# PATH 配置
export PATH="$HOME/.local/bin:$PATH"
EOF

    print_success ".zshrc 配置完成"
}

# ============================================
# 主程序
# ============================================

echo ""
echo "============================================"
echo "    Oh My Zsh 配置脚本"
echo "============================================"
echo ""

# 检查 Oh My Zsh 是否已安装
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    print_error "Oh My Zsh 未安装，请先安装"
    echo ""
    echo "安装方法:"
    echo "  git clone https://gitee.com/mirrors/oh-my-zsh.git ~/.oh-my-zsh"
    echo "  cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc"
    exit 1
fi

# 检查 zsh
if ! command -v zsh &> /dev/null; then
    print_warning "zsh 未安装，部分功能可能不可用"
fi

# 执行配置
install_powerlevel10k
install_zsh_plugins
configure_zshrc

echo ""
print_success "配置完成!"
echo ""
echo "下一步:"
echo "  1. 运行 'source ~/.zshrc' 或重新打开终端"
echo "  2. 首次启动会进入 powerlevel10k 配置向导"
echo "  3. 如果跳过了向导，可以运行 'p10k configure' 重新配置"
echo ""
