#!/bin/bash

# ============================================
# Linux CLI Tools Installer (用户级安装)
# 无需 root 权限，所有工具安装到 ~/.local
# 仅使用 Gitee 镜像源
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

command_exists() {
    command -v "$1" &> /dev/null
}

# 确保 ~/.local/bin 存在
mkdir -p "$HOME/.local/bin"

# 添加到 PATH
export PATH="$HOME/.local/bin:$PATH"
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

# ============================================
# 安装函数
# ============================================

install_zoxide() {
    print_info "安装 zoxide..."
    if command_exists zoxide; then
        print_warning "zoxide 已安装，跳过"
        return 0
    fi

    # 从 GitHub releases 下载二进制
    local arch=$(uname -m)
    case $arch in
        x86_64) arch="x86_64-unknown-linux-musl" ;;
        aarch64) arch="aarch64-unknown-linux-musl" ;;
        *) print_error "不支持的架构: $arch"; return 1 ;;
    esac

    local download_url="https://github.com/ajeetdsouza/zoxide/releases/download/v0.9.7/zoxide-${arch}"
    curl -L "$download_url" -o "$HOME/.local/bin/zoxide"
    chmod +x "$HOME/.local/bin/zoxide"

    print_success "zoxide 安装完成 -> ~/.local/bin/zoxide"
}

install_eza() {
    print_info "安装 eza..."
    if command_exists eza; then
        print_warning "eza 已安装，跳过"
        return 0
    fi

    local arch=$(uname -m)
    case $arch in
        x86_64) arch="x86_64-unknown-linux-gnu" ;;
        aarch64) arch="aarch64-unknown-linux-gnu" ;;
        *) print_error "不支持的架构: $arch"; return 1 ;;
    esac

    local download_url="https://github.com/eza-community/eza/releases/download/v0.19.2/eza_${arch}.tar.gz"
    curl -L "$download_url" | tar xz -C "$HOME/.local/bin" eza

    print_success "eza 安装完成 -> ~/.local/bin/eza"
}

install_bat() {
    print_info "安装 bat..."
    if command_exists bat; then
        print_warning "bat 已安装，跳过"
        return 0
    fi

    local arch=$(uname -m)
    case $arch in
        x86_64) arch="x86_64-unknown-linux-musl" ;;
        aarch64) arch="aarch64-unknown-linux-musl" ;;
        *) print_error "不支持的架构: $arch"; return 1 ;;
    esac

    local download_url="https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-${arch}.tar.gz"
    local tmp_dir=$(mktemp -d)
    curl -L "$download_url" | tar xz -C "$tmp_dir" --strip-components=1
    cp "$tmp_dir/bat" "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/bat"
    rm -rf "$tmp_dir"

    print_success "bat 安装完成 -> ~/.local/bin/bat"
}

install_fzf() {
    print_info "安装 fzf..."
    if command_exists fzf; then
        print_warning "fzf 已安装，跳过"
        return 0
    fi

    # 从 GitHub 下载二进制
    local arch=$(uname -m)
    case $arch in
        x86_64) arch="amd64" ;;
        aarch64) arch="arm64" ;;
        *) print_error "不支持的架构: $arch"; return 1 ;;
    esac

    local download_url="https://github.com/junegunn/fzf/releases/download/v0.53.0/fzf-0.53.0-linux_${arch}.tar.gz"
    curl -L "$download_url" | tar xz -C "$HOME/.local/bin" fzf
    chmod +x "$HOME/.local/bin/fzf"

    print_success "fzf 安装完成 -> ~/.local/bin/fzf"
}

install_oh_my_zsh() {
    print_info "安装 Oh My Zsh..."
    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_warning "Oh My Zsh 已安装，跳过"
        return 0
    fi

    # 使用 Gitee 镜像
    git clone https://gitee.com/mirrors/oh-my-zsh.git "$HOME/.oh-my-zsh"
    cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"

    print_success "Oh My Zsh 安装完成"
}

install_powerlevel10k() {
    print_info "安装 powerlevel10k 主题..."
    local theme_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

    if [ -d "$theme_dir" ]; then
        print_warning "powerlevel10k 已安装，跳过"
        return 0
    fi

    git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git "$theme_dir"
    print_success "powerlevel10k 主题安装完成"
}

install_zsh_plugins() {
    print_info "安装 zsh 插件..."
    local plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

    # 只安装 Gitee 有的插件
    for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
        local plugin_path="$plugins_dir/$plugin"
        if [ -d "$plugin_path" ]; then
            print_warning "$plugin 已安装，跳过"
        else
            git clone "https://gitee.com/zsh-users/${plugin}.git" "$plugin_path"
            print_success "$plugin 安装完成"
        fi
    done
}

configure_zsh() {
    print_info "配置 .zshrc..."

    local zshrc="$HOME/.zshrc"
    if [ ! -f "$zshrc" ]; then
        if [ -f "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" ]; then
            cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$zshrc"
        else
            print_error "找不到 zshrc 模板"
            return 1
        fi
    fi

    # 设置主题
    sed -i 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$zshrc"

    # 设置插件
    sed -i 's/plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zoxide fzf)/' "$zshrc"

    # 添加配置
    if ! grep -q "zoxide init" "$zshrc" 2>/dev/null; then
        cat >> "$zshrc" << 'EOF'

# ========== CLI Tools ==========
eval "$(zoxide init bash)"

# eza aliases
alias ls='eza --icons=auto'
alias ll='eza -lah --icons=auto'
alias lt='eza --tree --level=2 --icons=auto'

# bat alias
alias cat='bat --paging=never'
EOF
    fi

    print_success ".zshrc 配置完成"
}

# ============================================
# 主菜单
# ============================================

show_menu() {
    echo ""
    echo "============================================"
    echo "    Linux CLI Tools 安装脚本 (用户级)"
    echo "    无需 root 权限"
    echo "============================================"
    echo ""
    echo "Shell 环境:"
    echo "  1) Oh My Zsh                    $( [ -d "$HOME/.oh-my-zsh" ] && echo '[已安装]' || echo '[未安装]')"
    echo "  2) powerlevel10k 主题           $( [ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ] && echo '[已安装]' || echo '[未安装]')"
    echo "  3) zsh 插件 (Gitee 镜像)"
    echo ""
    echo "命令行工具:"
    echo "  4) zoxide (智能目录跳转)        $(command_exists zoxide && echo '[已安装]' || echo '[未安装]')"
    echo "  5) eza (现代化 ls)              $(command_exists eza && echo '[已安装]' || echo '[未安装]')"
    echo "  6) bat (现代化 cat)             $(command_exists bat && echo '[已安装]' || echo '[未安装]')"
    echo "  7) fzf (模糊搜索)               $(command_exists fzf && echo '[已安装]' || echo '[未安装]')"
    echo ""
    echo "预设组合:"
    echo "  a) Shell 完整套装 (1-3)"
    echo "  b) 常用工具套装 (4-7)"
    echo "  c) 全部安装"
    echo ""
    echo "  q) 退出"
    echo ""
}

main() {
    while true; do
        show_menu
        read -p "请输入选项: " choices

        case "$choices" in
            q|Q)
                print_info "退出"
                exit 0
                ;;
            a|A)
                choices="1 2 3"
                ;;
            b|B)
                choices="4 5 6 7"
                ;;
            c|C)
                choices="1 2 3 4 5 6 7"
                ;;
        esac

        for choice in $choices; do
            case "$choice" in
                1) install_oh_my_zsh ;;
                2) install_powerlevel10k ;;
                3) install_zsh_plugins ;;
                4) install_zoxide ;;
                5) install_eza ;;
                6) install_bat ;;
                7) install_fzf ;;
                *) print_warning "无效选项: $choice" ;;
            esac
        done

        # 配置
        if [[ "$choices" =~ [123] ]]; then
            read -p "是否自动配置 .zshrc? (y/n): " configure
            if [[ "$configure" =~ ^[Yy]$ ]]; then
                configure_zsh
            fi
        fi

        echo ""
        print_success "完成!"
        echo ""
        read -p "按回车继续..."
    done
}

main
