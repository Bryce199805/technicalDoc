#!/bin/bash

# LazyVim 自动安装脚本
# 支持 Linux 和 macOS 系统
# 作者: Corner
# 版本: 2.0.0

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        log_error "不支持的操作系统: $OSTYPE"
        exit 1
    fi
}

# 检测包管理器
detect_package_manager() {
    if command -v apt &> /dev/null; then
        echo "apt"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v brew &> /dev/null; then
        echo "brew"
    else
        log_error "未找到支持的包管理器"
        exit 1
    fi
}

# 检查是否需要 sudo
need_sudo() {
    if [[ $EUID -eq 0 ]]; then
        echo ""
    else
        echo "sudo"
    fi
}

# 获取系统 GLIBC 版本
get_glibc_version() {
    ldd --version 2>&1 | head -n1 | grep -oE '[0-9]+\.[0-9]+$' || echo "0.0"
}

# 版本比较: 返回 0 表示 $1 >= $2
version_gte() {
    local IFS='.'
    read -ra V1 <<< "$1"
    read -ra V2 <<< "$2"
    for i in "${!V2[@]}"; do
        local v1=${V1[$i]:-0}
        local v2=${V2[$i]:-0}
        if (( 10#$v1 > 10#$v2 )); then return 0; fi
        if (( 10#$v1 < 10#$v2 )); then return 1; fi
    done
    return 0
}

# 安装 ripgrep
install_ripgrep() {
    if command -v rg &> /dev/null; then
        log_success "ripgrep 已安装"
        return 0
    fi

    local SUDO=$(need_sudo)
    log_info "正在安装 ripgrep..."

    cd /tmp
    wget -O ripgrep.tar.gz https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep-14.1.0-x86_64-unknown-linux-musl.tar.gz
    tar -xzf ripgrep.tar.gz
    $SUDO cp ripgrep-14.1.0-x86_64-unknown-linux-musl/rg /usr/local/bin/
    rm -rf ripgrep.tar.gz ripgrep-14.1.0-x86_64-unknown-linux-musl
    cd - > /dev/null

    log_success "ripgrep 安装完成"
}

# 安装 fzf
install_fzf() {
    if command -v fzf &> /dev/null; then
        log_success "fzf 已安装"
        return 0
    fi

    log_info "正在安装 fzf..."

    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --bin

    local SUDO=$(need_sudo)
    $SUDO cp ~/.fzf/bin/fzf /usr/local/bin/

    log_success "fzf 安装完成"
}

# 安装 fd
install_fd() {
    if command -v fd &> /dev/null; then
        log_success "fd 已安装"
        return 0
    fi

    local SUDO=$(need_sudo)
    log_info "正在安装 fd..."

    cd /tmp
    wget -O fd.tar.gz https://github.com/sharkdp/fd/releases/download/v9.0.0/fd-v9.0.0-x86_64-unknown-linux-musl.tar.gz
    tar -xzf fd.tar.gz
    $SUDO cp fd-v9.0.0-x86_64-unknown-linux-musl/fd /usr/local/bin/
    rm -rf fd.tar.gz fd-v9.0.0-x86_64-unknown-linux-musl
    cd - > /dev/null

    log_success "fd 安装完成"
}

# 安装基础依赖 (Linux)
install_linux_deps() {
    local pkg_manager=$1
    local SUDO=$(need_sudo)

    log_info "正在安装基础依赖..."

    case $pkg_manager in
        "apt")
            $SUDO apt update
            $SUDO apt install -y git cmake ninja-build gettext curl unzip build-essential wget libicu-dev libclang-dev
            # 尝试安装，如果失败则从源码安装
            $SUDO apt install -y ripgrep fzf fd-find || true
            ;;
        "yum"|"dnf")
            $SUDO $pkg_manager update -y
            $SUDO $pkg_manager install -y git cmake ninja-build gettext curl unzip gcc gcc-c++ make wget tar gzip fontconfig libicu libclang-devel
            # 尝试安装，如果失败则从源码安装
            $SUDO $pkg_manager install -y ripgrep fzf fd-find 2>/dev/null || true
            ;;
    esac

    # 安装可能缺失的工具
    install_ripgrep
    install_fzf
    install_fd

    # 安装 lazygit
    log_info "正在安装 lazygit..."
    if ! command -v lazygit &> /dev/null; then
        cd /tmp
        wget -O lazygit.tar.gz https://github.com/jesseduffield/lazygit/releases/download/v0.42.0/lazygit_0.42.0_Linux_x86_64.tar.gz
        tar -xzf lazygit.tar.gz
        $SUDO mv lazygit /usr/local/bin/
        rm lazygit.tar.gz
        cd - > /dev/null
        log_success "lazygit 安装完成"
    else
        log_success "lazygit 已安装"
    fi

    log_success "基础依赖安装完成"
}

# 安装基础依赖 (macOS)
install_macos_deps() {
    log_info "正在安装基础依赖..."

    # 检查是否安装了 Homebrew
    if ! command -v brew &> /dev/null; then
        log_info "正在安装 Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # 安装基础工具
    brew install neovim git curl fzf ripgrep fd lazygit

    # 安装 Xcode 命令行工具
    if ! command -v clang &> /dev/null; then
        log_info "正在安装 Xcode 命令行工具..."
        xcode-select --install
    fi

    log_success "基础依赖安装完成"
}

# 编译安装 Neovim (Linux)
install_neovim_linux() {
    local SUDO=$(need_sudo)

    log_info "正在编译安装 Neovim..."

    # 检查是否已经安装了足够新的版本
    if command -v nvim &> /dev/null; then
        local version=$(nvim --version | head -n1 | grep -o 'v[0-9]\+\.[0-9]\+')
        local major=$(echo $version | cut -d. -f1 | tr -d 'v')
        local minor=$(echo $version | cut -d. -f2)

        if [[ $major -gt 0 ]] || [[ $major -eq 0 && $minor -ge 9 ]]; then
            log_success "Neovim 版本已满足要求: $version"
            return 0
        fi
    fi

    # 克隆并编译 Neovim
    cd /tmp
    git clone https://github.com/neovim/neovim.git
    cd neovim

    make CMAKE_BUILD_TYPE=RelWithDebInfo
    $SUDO make install

    cd ..
    rm -rf neovim

    log_success "Neovim 安装完成"
}

# 安装 tree-sitter CLI（处理 GLIBC 兼容性）
install_tree_sitter_cli() {
    if command -v tree-sitter &> /dev/null; then
        log_success "tree-sitter CLI 已安装: $(tree-sitter --version 2>/dev/null || echo 'unknown')"
        return 0
    fi

    local SUDO=$(need_sudo)
    local glibc_version=$(get_glibc_version)

    if version_gte "$glibc_version" "2.39"; then
        log_info "GLIBC $glibc_version >= 2.39，Mason 会自动安装 tree-sitter CLI"
        return 0
    fi

    log_warning "GLIBC $glibc_version < 2.39，预编译 tree-sitter CLI 不兼容"
    log_info "正在通过 Rust 从源码编译 tree-sitter CLI..."

    # 安装 Rust（如果未安装）
    if ! command -v cargo &> /dev/null; then
        log_info "正在安装 Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi

    # 设置 libclang 路径
    local libclang_path=$(find /usr/lib -name "libclang.so*" 2>/dev/null | head -1 | xargs dirname 2>/dev/null)
    if [[ -n "$libclang_path" ]]; then
        export LIBCLANG_PATH="$libclang_path"
        log_info "设置 LIBCLANG_PATH=$libclang_path"
    fi

    # 通过 cargo 编译安装
    cargo install tree-sitter-cli

    # 复制到系统路径
    $SUDO ln -sf "$HOME/.cargo/bin/tree-sitter" /usr/local/bin/tree-sitter

    log_success "tree-sitter CLI 编译安装完成: $(tree-sitter --version)"
}

# 安装 Nerd Font (Linux)
install_nerd_font_linux() {
    log_info "正在安装 Nerd Font..."

    mkdir -p ~/.local/share/fonts

    cd ~
    wget -O CascadiaCode.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/CascadiaCode.zip
    unzip -o CascadiaCode.zip -d ~/.local/share/fonts/
    rm CascadiaCode.zip

    # 刷新字体缓存（如果 fc-cache 可用）
    if command -v fc-cache &> /dev/null; then
        fc-cache -fv
    else
        log_warning "fc-cache 不可用，字体可能需要重启终端后才能生效"
    fi

    log_success "Nerd Font 安装完成"
}

# 安装 Nerd Font (macOS)
install_nerd_font_macos() {
    log_info "正在安装 Nerd Font..."

    brew tap homebrew/cask-fonts
    brew install --cask font-caskaydia-cove-nerd-font

    log_success "Nerd Font 安装完成"
}

# 安装 LazyVim
install_lazyvim() {
    log_info "正在安装 LazyVim..."

    # 备份现有配置
    if [[ -d ~/.config/nvim ]]; then
        log_warning "发现现有 Neovim 配置，正在备份..."
        mv ~/.config/nvim ~/.config/nvim.bak.$(date +%Y%m%d_%H%M%S)
    fi

    # 清理缓存
    rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim 2>/dev/null || true

    # 克隆 LazyVim 配置
    git clone https://github.com/LazyVim/starter ~/.config/nvim
    rm -rf ~/.config/nvim/.git

    log_success "LazyVim 配置安装完成"
}

# 配置 Lazy Extras（预装推荐插件）
configure_extras() {
    log_info "正在配置 Lazy Extras 插件..."

    mkdir -p ~/.config/nvim/lua/plugins

    cat > ~/.config/nvim/lua/plugins/extras.lua << 'LUAEOF'
-- 预装的 Lazy Extras 插件
-- 由 lazyvim-installer 自动生成
return {
  -- 语言支持
  { import = "lazyvim.plugins.extras.lang.markdown" },

  -- 编码增强
  { import = "lazyvim.plugins.extras.coding.mini-surround" },
  { import = "lazyvim.plugins.extras.coding.yanky" },

  -- 编辑器增强
  { import = "lazyvim.plugins.extras.editor.inc-rename" },

  -- UI 增强
  { import = "lazyvim.plugins.extras.ui.treesitter-context" },
}
LUAEOF

    log_success "Lazy Extras 插件配置完成"
}

# 配置 OSC52 剪贴板（SSH/tmux 环境）
configure_clipboard() {
    if [[ -z "$SSH_CLIENT" && -z "$SSH_TTY" ]]; then
        log_info "非 SSH 环境，跳过 OSC52 剪贴板配置"
        return 0
    fi

    log_info "检测到 SSH 环境，正在配置 OSC52 剪贴板..."

    mkdir -p ~/.config/nvim/lua/plugins

    cat > ~/.config/nvim/lua/plugins/osc52.lua << 'LUAEOF'
return {
  {
    "ojroques/nvim-osc52",
    config = function()
      local osc52 = require("osc52")
      osc52.setup({
        max_length = 0,
        silent = true,
        trim = false,
      })

      -- 自定义 OSC52 发送：通过 tmux client tty 直接写入
      -- nvim 的 stderr 在 tmux 中不连接终端 pty，需要绕过
      local function send_osc52(text)
        local b64 = require("osc52.base64").enc(text)
        local seq = string.format("\027]52;c;%s\007", b64)

        if os.getenv("TMUX") then
          local handle = io.popen("tmux list-clients -F '#{client_tty}' 2>/dev/null")
          if handle then
            local ttys = handle:read("*a")
            handle:close()
            for tty in ttys:gmatch("[^\n]+") do
              local f = io.open(tty, "w")
              if f then
                f:write(seq)
                f:close()
                return
              end
            end
          end
        end

        -- fallback: 非 tmux 环境使用插件默认方式
        osc52.copy(text)
      end

      vim.api.nvim_create_autocmd("TextYankPost", {
        callback = function()
          if vim.v.event.operator == "y" then
            local reg = vim.v.event.regname
            local text = vim.fn.getreg(reg)
            if text and #text > 0 then
              send_osc52(text)
            end
          end
        end,
      })
    end,
  },
}
LUAEOF

    # 启用系统剪贴板集成
    local options_file="$HOME/.config/nvim/lua/config/options.lua"
    if ! grep -q "vim.opt.clipboard" "$options_file" 2>/dev/null; then
        echo "" >> "$options_file"
        echo '-- 系统剪贴板集成（OSC52 通过 TextYankPost 同步到终端剪贴板）' >> "$options_file"
        echo 'vim.opt.clipboard = "unnamedplus"' >> "$options_file"
    fi

    log_success "OSC52 剪贴板配置完成"
}

# 配置 Markdown（LSP + 预览 + lint 修复）
configure_markdown() {
    log_info "正在配置 Markdown 支持..."

    mkdir -p ~/.config/nvim/lua/plugins

    # 检测服务器 IP（用于远程预览）
    local server_ip
    server_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [[ -z "$server_ip" ]]; then
        server_ip="0.0.0.0"
    fi

    cat > ~/.config/nvim/lua/plugins/markdown.lua << LUAEOF
return {
  -- marksman LSP
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.marksman = {
        mason = true,
        filetypes = { "markdown", "markdown.mdx" },
      }
      return opts
    end,
  },
  -- 禁用 markdownlint-cli2（避免 ENOENT 报错）
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        markdown = {},
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        ["markdown"] = { "prettier" },
        ["markdown.mdx"] = { "prettier" },
      },
    },
  },
  -- Markdown 远程预览（SSH 环境通过 IP:端口 在本地浏览器访问）
  {
    "iamcco/markdown-preview.nvim",
    optional = true,
    opts = function()
      vim.g.mkdp_open_to_the_world = 1
      vim.g.mkdp_open_ip = "${server_ip}"
      vim.g.mkdp_port = 8888
      vim.g.mkdp_echo_preview_url = 1
      vim.g.mkdp_browser = "echo"
    end,
  },
}
LUAEOF

    log_success "Markdown 支持配置完成（LSP + 预览 + lint 修复）"
}

# 安装插件
install_plugins() {
    log_info "正在安装插件 (这可能需要几分钟)..."

    nvim --headless -c "Lazy! sync" -c "qa" 2>&1 || true

    # 安装 Mason 工具
    log_info "正在安装 Mason 工具..."
    nvim --headless +"lua require('mason-registry').refresh()" +"MasonInstall marksman" +"sleep 30" +qa 2>&1 || true

    log_success "插件安装完成"
}

# 显示安装完成信息
show_completion_info() {
    echo
    log_success "🎉 LazyVim 安装完成！"
    echo
    echo "已预装以下功能："
    echo "  - Markdown 支持 (marksman LSP + 远程预览)"
    echo "  - 编码增强 (mini-surround, yanky, inc-rename)"
    echo "  - UI 增强 (treesitter-context)"
    if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
        echo "  - SSH 剪贴板互通 (OSC52)"
    fi
    echo "  - Markdown 预览: nvim 中 :MarkdownPreview，浏览器访问 http://$(hostname -I 2>/dev/null | awk '{print $1}'):8888"
    echo
    echo "下一步操作："
    echo "1. 重启终端或重新加载终端配置"
    echo "2. 运行 'nvim' 启动 LazyVim"
    echo "3. 运行 './check-system.sh' 验证安装"
    echo
    echo "常用快捷键："
    echo "  <Space>ff  文件查找      <Space>fg  文本搜索"
    echo "  <Space>e   文件浏览器    <Space>gg  LazyGit"
    echo "  gd         跳转定义      gr         查看引用"
    echo "  <Space>cr  重命名        <Space>ca  代码操作"
    echo
}

# 主函数
main() {
    echo "🚀 LazyVim 自动安装脚本 v2.0.0"
    echo "================================="
    echo

    # 检测操作系统
    local os=$(detect_os)
    log_info "检测到操作系统: $os"

    # 检测包管理器
    local pkg_manager=$(detect_package_manager)
    log_info "检测到包管理器: $pkg_manager"

    # 安装基础依赖
    if [[ $os == "linux" ]]; then
        install_linux_deps $pkg_manager
        install_neovim_linux
        install_tree_sitter_cli
        install_nerd_font_linux
    else
        install_macos_deps
        install_nerd_font_macos
    fi

    # 安装 LazyVim
    install_lazyvim

    # 配置开箱即用的插件
    configure_extras
    configure_clipboard
    configure_markdown

    # 安装插件
    install_plugins

    # 显示完成信息
    show_completion_info
}

# 检查运行用户
if [[ $EUID -eq 0 ]]; then
    log_info "检测到以 root 用户运行"
fi

# 运行主函数
main "$@"
