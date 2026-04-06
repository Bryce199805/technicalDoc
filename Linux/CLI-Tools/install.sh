#!/bin/bash

# ============================================
# Linux CLI Tools Installer
# 交互式安装脚本 - 支持用户级安装
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查命令是否存在
command_exists() {
    command -v "$1" &> /dev/null
}

# ============================================
# 安装选项菜单
# ============================================

show_menu() {
    echo ""
    echo "============================================"
    echo "    Linux CLI Tools 快速安装脚本"
    echo "============================================"
    echo ""
    echo "Shell 环境:"
    echo "  1) zsh                           $(command_exists zsh && echo '[已安装]' || echo '[未安装]')"
    echo "  2) Oh My Zsh                     $( [ -d "$HOME/.oh-my-zsh" ] && echo '[已安装]' || echo '[未安装]')"
    echo "  3) powerlevel10k 主题            $( [ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ] && echo '[已安装]' || echo '[未安装]')"
    echo "  4) zsh 插件集 (autosuggestions, syntax-highlighting, completions, fzf-tab)"
    echo ""
    echo "命令行工具:"
    echo "  5) zoxide (智能目录跳转)         $(command_exists zoxide && echo '[已安装]' || echo '[未安装]')"
    echo "  6) eza (现代化 ls)               $(command_exists eza && echo '[已安装]' || echo '[未安装]')"
    echo "  7) bat (现代化 cat)              $(command_exists bat && echo '[已安装]' || echo '[未安装]')"
    echo "  8) fzf (模糊搜索)                $(command_exists fzf && echo '[已安装]' || echo '[未安装]')"
    echo "  9) btop (系统监控)               $(command_exists btop && echo '[已安装]' || echo '[未安装]')"
    echo " 10) tldr (简化版 man)             $(command_exists tldr && echo '[已安装]' || echo '[未安装]')"
    echo ""
    echo "编辑器与终端:"
    echo " 11) Neovim + LazyVim              $(command_exists nvim && echo '[已安装]' || echo '[未安装]')"
    echo " 12) Zellij (终端复用)             $(command_exists zellij && echo '[已安装]' || echo '[未安装]')"
    echo ""
    echo "预设组合:"
    echo "  a) Shell 完整套装 (1-4)"
    echo "  b) 常用工具套装 (5-8)"
    echo "  c) 全部安装 (1-12)"
    echo ""
    echo "  q) 退出"
    echo ""
}

# ============================================
# 安装函数
# ============================================

# 安装 zsh
install_zsh() {
    print_info "安装 zsh..."
    if command_exists zsh; then
        print_warning "zsh 已安装，跳过"
        return 0
    fi

    # 检测包管理器
    if command_exists apt; then
        sudo apt update && sudo apt install -y zsh
    elif command_exists yum; then
        sudo yum install -y zsh
    elif command_exists dnf; then
        sudo dnf install -y zsh
    else
        print_error "不支持的包管理器，请手动安装 zsh"
        return 1
    fi

    print_success "zsh 安装完成"
}

# 安装 Oh My Zsh
install_oh_my_zsh() {
    print_info "安装 Oh My Zsh..."
    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_warning "Oh My Zsh 已安装，跳过"
        return 0
    fi

    # 检查 git 和 curl/wget
    if ! command_exists git; then
        print_error "需要先安装 git"
        return 1
    fi

    if command_exists curl; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    elif command_exists wget; then
        sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        print_error "需要 curl 或 wget"
        return 1
    fi

    print_success "Oh My Zsh 安装完成"
}

# 安装 powerlevel10k 主题
install_powerlevel10k() {
    print_info "安装 powerlevel10k 主题..."
    local theme_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

    if [ -d "$theme_dir" ]; then
        print_warning "powerlevel10k 已安装，跳过"
        return 0
    fi

    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$theme_dir"
    print_success "powerlevel10k 主题安装完成"
}

# 安装 zsh 插件
install_zsh_plugins() {
    print_info "安装 zsh 插件..."
    local plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

    # 插件列表
    declare -A plugins=(
        ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
        ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
        ["zsh-completions"]="https://github.com/zsh-users/zsh-completions"
        ["fzf-tab"]="https://github.com/Aloxaf/fzf-tab"
    )

    for plugin in "${!plugins[@]}"; do
        local plugin_path="$plugins_dir/$plugin"
        if [ -d "$plugin_path" ]; then
            print_warning "$plugin 已安装，跳过"
        else
            git clone "${plugins[$plugin]}" "$plugin_path"
            print_success "$plugin 安装完成"
        fi
    done
}

# 安装 zoxide
install_zoxide() {
    print_info "安装 zoxide..."
    if command_exists zoxide; then
        print_warning "zoxide 已安装，跳过"
        return 0
    fi

    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

    # 添加到 PATH
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    fi

    export PATH="$HOME/.local/bin:$PATH"
    print_success "zoxide 安装完成"
}

# 安装 eza
install_eza() {
    print_info "安装 eza..."
    if command_exists eza; then
        print_warning "eza 已安装，跳过"
        return 0
    fi

    # 检测包管理器
    if command_exists apt; then
        sudo apt update
        sudo apt install -y gpg
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de/stable ./" | sudo tee /etc/apt/sources.list.d/gierens.list
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        sudo apt update && sudo apt install -y eza
    elif command_exists yum || command_exists dnf; then
        sudo dnf install -y eza || sudo yum install -y eza
    else
        # 从 GitHub releases 下载二进制
        local arch=$(uname -m)
        case $arch in
            x86_64) arch="x86_64" ;;
            aarch64) arch="aarch64" ;;
            *) print_error "不支持的架构: $arch"; return 1 ;;
        esac

        local latest_url=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest | grep "browser_download_url.*${arch}-unknown-linux-gnu.tar.gz\"" | cut -d '"' -f 4)
        curl -L "$latest_url" | tar xz -C "$HOME/.local/bin" eza
        print_success "eza 安装完成 (二进制)"
        return 0
    fi

    print_success "eza 安装完成"
}

# 安装 bat
install_bat() {
    print_info "安装 bat..."
    if command_exists bat; then
        print_warning "bat 已安装，跳过"
        return 0
    fi

    if command_exists apt; then
        sudo apt update && sudo apt install -y bat
        # Ubuntu 上 bat 二进制名为 batcat，创建软链接
        if command_exists batcat && ! command_exists bat; then
            mkdir -p "$HOME/.local/bin"
            ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"
        fi
    elif command_exists yum || command_exists dnf; then
        sudo dnf install -y bat || sudo yum install -y bat
    else
        print_warning "请手动安装 bat"
        return 1
    fi

    print_success "bat 安装完成"
}

# 安装 fzf
install_fzf() {
    print_info "安装 fzf..."
    if command_exists fzf; then
        print_warning "fzf 已安装，跳过"
        return 0
    fi

    if command_exists apt; then
        sudo apt update && sudo apt install -y fzf
    else
        # 从 GitHub 安装
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
        "$HOME/.fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
    fi

    print_success "fzf 安装完成"
}

# 安装 btop
install_btop() {
    print_info "安装 btop..."
    if command_exists btop; then
        print_warning "btop 已安装，跳过"
        return 0
    fi

    if command_exists apt; then
        sudo apt update && sudo apt install -y btop
    elif command_exists yum || command_exists dnf; then
        sudo dnf install -y btop || sudo yum install -y btop
    else
        print_warning "请手动安装 btop"
        return 1
    fi

    print_success "btop 安装完成"
}

# 安装 tldr
install_tldr() {
    print_info "安装 tldr..."
    if command_exists tldr; then
        print_warning "tldr 已安装，跳过"
        return 0
    fi

    if command_exists apt; then
        sudo apt update && sudo apt install -y tldr
    else
        # 使用 npm 或 pip 安装
        if command_exists npm; then
            npm install -g tldr
        elif command_exists pip3; then
            pip3 install tldr
        else
            print_warning "请手动安装 tldr (需要 npm 或 pip)"
            return 1
        fi
    fi

    # 更新缓存
    tldr --update 2>/dev/null || true

    print_success "tldr 安装完成"
}

# 安装 Neovim + LazyVim
install_neovim() {
    print_info "安装 Neovim..."
    if command_exists nvim; then
        print_warning "Neovim 已安装，跳过"
        return 0
    fi

    if command_exists apt; then
        sudo apt update && sudo apt install -y neovim
    elif command_exists yum || command_exists dnf; then
        sudo dnf install -y neovim || sudo yum install -y neovim
    else
        print_warning "请手动安装 Neovim"
        return 1
    fi

    # 安装 LazyVim starter
    print_info "配置 LazyVim..."
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim" 2>/dev/null || true
    rm -rf "$HOME/.config/nvim/.git"

    print_success "Neovim + LazyVim 安装完成"
}

# 安装 Zellij
install_zellij() {
    print_info "安装 Zellij..."
    if command_exists zellij; then
        print_warning "Zellij 已安装，跳过"
        return 0
    fi

    if command_exists apt; then
        sudo apt update && sudo apt install -y zellij
    else
        # 从 GitHub releases 下载
        local arch=$(uname -m)
        case $arch in
            x86_64) arch="x86_64" ;;
            aarch64) arch="aarch64" ;;
            *) print_error "不支持的架构: $arch"; return 1 ;;
        esac

        local latest_url=$(curl -s https://api.github.com/repos/zellij-org/zellij/releases/latest | grep "browser_download_url.*${arch}-unknown-linux-musl.tar.gz\"" | cut -d '"' -f 4)
        mkdir -p "$HOME/.local/bin"
        curl -L "$latest_url" | tar xz -C "$HOME/.local/bin" zellij
    fi

    print_success "Zellij 安装完成"
}

# ============================================
# 配置函数
# ============================================

configure_zsh() {
    print_info "配置 .zshrc..."

    local zshrc="$HOME/.zshrc"
    if [ ! -f "$zshrc" ]; then
        cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$zshrc"
    fi

    # 设置主题
    sed -i 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$zshrc"

    # 设置插件
    local plugins="git zsh-autosuggestions zsh-syntax-highlighting zsh-completions fzf-tab zoxide fzf"
    sed -i "s/plugins=(.*)/plugins=($plugins)/" "$zshrc"

    # 添加别名
    cat >> "$zshrc" << 'EOF'

# ========== CLI Tools Aliases ==========
# eza aliases
alias ls='eza --icons=auto'
alias l='eza -lh --icons=auto --group-directories-first'
alias ll='eza -lah --icons=auto --group-directories-first'
alias lt='eza --tree --level=2 --icons=auto'
alias tt='eza --tree --level=3 --icons=auto'
alias ta='eza --tree --level=2 --icons=auto -a'

# bat aliases
alias cat='bat --paging=never'
alias c='bat'
alias cl='bat --style=numbers --line-range'

# zoxide
eval "$(zoxide init zsh)"

# fzf
eval "$(fzf --zsh)"

# System aliases
alias ..='cd ..'
alias ...='cd ../..'
alias h='history'
EOF

    print_success ".zshrc 配置完成"
}

# ============================================
# 主程序
# ============================================

main() {
    # 确保 .local/bin 存在
    mkdir -p "$HOME/.local/bin"

    while true; do
        show_menu
        read -p "请输入选项 (多个选项用空格分隔): " choices

        case "$choices" in
            q|Q)
                print_info "退出安装"
                exit 0
                ;;
            a|A)
                choices="1 2 3 4"
                ;;
            b|B)
                choices="5 6 7 8"
                ;;
            c|C)
                choices="1 2 3 4 5 6 7 8 9 10 11 12"
                ;;
        esac

        for choice in $choices; do
            case "$choice" in
                1) install_zsh ;;
                2) install_oh_my_zsh ;;
                3) install_powerlevel10k ;;
                4) install_zsh_plugins ;;
                5) install_zoxide ;;
                6) install_eza ;;
                7) install_bat ;;
                8) install_fzf ;;
                9) install_btop ;;
                10) install_tldr ;;
                11) install_neovim ;;
                12) install_zellij ;;
                *)
                    print_warning "无效选项: $choice"
                    ;;
            esac
        done

        # 如果安装了 Shell 组件，提示配置
        if [[ "$choices" =~ [1234] ]]; then
            read -p "是否自动配置 .zshrc? (y/n): " configure
            if [[ "$configure" =~ ^[Yy]$ ]]; then
                configure_zsh
            fi
        fi

        echo ""
        print_success "安装完成!"
        echo ""
        read -p "按回车继续..."
    done
}

main
