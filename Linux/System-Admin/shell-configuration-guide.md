# Shell 配置指南: zsh 与 bash

本文档详细介绍 zsh 和 bash 的配置、区别以及最佳实践。

---

## 目录

1. [Shell 概述](#shell-概述)
2. [bash 配置](#bash-配置)
3. [zsh 配置](#zsh-配置)
4. [环境变量管理](#环境变量管理)
5. [常见问题](#常见问题)
6. [最佳实践](#最佳实践)

---

## Shell 概述

### 什么是 Shell?

Shell 是操作系统的命令行解释器,负责接收用户命令并调用操作系统内核执行。

### 常见 Shell 类型

| Shell | 说明 | 默认系统 |
|-------|------|---------|
| **bash** | Bourne Again Shell,最广泛使用 | 大多数 Linux 发行版、旧版 macOS |
| **zsh** | Z Shell,功能更强大,兼容 bash | 新版 macOS(Catalina+)、流行发行版 |
| **sh** | Bourne Shell,POSIX 标准 | Unix 系统 |
| **dash** | Debian Almquist Shell,轻量级 | Debian/Ubuntu (作为 /bin/sh) |
| **fish** | Friendly Interactive Shell,用户友好 | 需手动安装 |

### 查看当前 Shell

```bash
# 当前使用的 shell
echo $SHELL

# 当前 shell 进程
echo $0

# 已安装的 shell
cat /etc/shells

# 切换默认 shell
chsh -s $(which zsh)
chsh -s $(which bash)
```

### bash vs zsh 对比

| 特性 | bash | zsh |
|------|------|-----|
| 兼容性 | POSIX 标准 | 兼容 bash |
| 自动补全 | 基础 | 强大(支持上下文感知) |
| 通配符 | 基础 glob | 扩展 glob |
| 插件 | 无原生支持 | 强大的插件系统 |
| 主题 | 无原生支持 | 主题框架(oh-my-zsh) |
| 命令历史 | 基础 | 高级(即时分享) |
| 拼写纠正 | 无 | 有 |
| 数组索引 | 从 0 开始 | 从 1 开始 |
| 启动速度 | 快 | 稍慢(可优化) |

---

## bash 配置

### 配置文件

#### 配置文件加载顺序

**登录 shell** (通过 SSH 或终端登录):
```
/etc/profile →
  ~/.bash_profile →
  ~/.bash_login →
  ~/.profile
```

**交互式非登录 shell** (打开新终端窗口):
```
/etc/bash.bashrc →
  ~/.bashrc
```

**注意**: 通常在 `~/.bash_profile` 中加载 `~/.bashrc`

#### 配置文件用途

| 文件 | 用途 | 加载时机 |
|------|------|---------|
| `/etc/profile` | 系统全局环境变量 | 登录 shell |
| `~/.bash_profile` | 用户环境变量 | 登录 shell |
| `~/.bash_login` | 用户环境变量(备选) | 登录 shell |
| `~/.profile` | 用户环境变量(通用) | 登录 shell |
| `~/.bashrc` | 别名、函数、交互设置 | 交互式 shell |
| `~/.bash_logout` | 退出时执行 | 退出 shell |

### ~/.bash_profile 示例

```bash
# ~/.bash_profile
# 登录 shell 配置

# 加载 ~/.bashrc
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# 登录时执行一次的命令
echo "Welcome to bash!"
```

### ~/.bashrc 示例

```bash
# ~/.bashrc
# 交互式 shell 配置

# ========== 环境变量 ==========
# PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# 编辑器
export EDITOR=nvim
export VISUAL=nvim

# 语言
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 历史记录
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"

# ========== 加载通用配置 ==========
[[ -f ~/.profile ]] && source ~/.profile

# ========== 加载 nvm ==========
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ========== 别名 ==========
# 常用命令
alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'

# npm 快捷命令
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install -g'
alias nr='npm run'
alias ns='npm start'
alias nt='npm test'

# git 快捷命令
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph'
alias gd='git diff'

# ========== 函数 ==========
# 创建目录并进入
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# 查找文件
ff() {
    find . -type f -name "*$1*"
}

# ========== 提示符 ==========
# 简单提示符
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# 或使用更详细的提示符
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[33m\]$(parse_git_branch)\[\033[00m\]\$ '

# ========== 自动补全 ==========
# 如果存在 bash-completion,加载它
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# ========== 交互设置 ==========
# 启用 vi 模式(可选)
# set -o vi

# 启用 cd 自动纠正
shopt -s cdspell

# 启用 ** 通配符
shopt -s globstar 2>/dev/null

# 历史命令追加而非覆盖
shopt -s histappend
```

### bash 补全

#### 安装 bash-completion

```bash
# Ubuntu/Debian
sudo apt install bash-completion

# macOS
brew install bash-completion@2

# CentOS/RHEL
sudo yum install bash-completion
```

#### 自定义补全

```bash
# ~/.bashrc

# 补全函数
_my_function() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="start stop restart status"

    if [[ ${cur} == * ]] ; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi
}

# 注册补全
complete -F _my_function mycommand
```

---

## zsh 配置

### 配置文件

#### 配置文件加载顺序

**登录 shell**:
```
/etc/zsh/zshenv → ~/.zshenv →
/etc/zsh/zprofile → ~/.zprofile →
/etc/zsh/zshrc → ~/.zshrc →
/etc/zsh/zlogin → ~/.zshlogin
```

**交互式 shell**:
```
/etc/zsh/zshenv → ~/.zshenv →
/etc/zsh/zshrc → ~/.zshrc
```

**退出 shell**:
```
~/.zlogout → /etc/zsh/zlogout
```

#### 配置文件用途

| 文件 | 用途 | 加载时机 | 建议内容 |
|------|------|---------|---------|
| `~/.zshenv` | 环境变量 | **所有** shell | PATH, EDITOR 等 |
| `~/.zprofile` | 登录设置 | 登录 shell | 启动程序 |
| `~/.zshrc` | 交互设置 | 交互式 shell | 别名、函数、插件 |
| `~/.zlogin` | 登录后执行 | 登录 shell | 登录消息 |
| `~/.zlogout` | 退出时执行 | 退出 shell | 清理操作 |

**最佳实践**:
- 环境变量放在 `~/.zshenv`
- 别名和函数放在 `~/.zshrc`
- 启动程序放在 `~/.zprofile`

### ~/.zshenv 示例

```bash
# ~/.zshenv
# 所有 shell 都会加载,放环境变量

# PATH
export PATH="$HOME/.local/bin:$PATH"

# 如果不使用 nvm,设置 npm 全局路径
# export PATH="$HOME/.npm-global/bin:$PATH"

# 编辑器
export EDITOR=nvim
export VISUAL=nvim

# 语言
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 其他环境变量
export NVM_DIR="$HOME/.nvm"
```

### ~/.zshrc 示例

```bash
# ~/.zshrc
# 交互式 shell 配置

# ========== Oh My Zsh 配置 ==========
export ZSH="$HOME/.oh-my-zsh"

# 主题
ZSH_THEME="robbyrussell"
# 或使用 powerlevel10k
# ZSH_THEME="powerlevel10k/powerlevel10k"

# 插件(按需启用)
plugins=(
    git                    # git 别名和补全
    zsh-autosuggestions    # 自动建议
    zsh-syntax-highlighting # 语法高亮
    zsh-completions        # 更多补全
    sudo                   # 双击 ESC 加 sudo
    copypath               # 复制当前路径
    copyfile               # 复制文件内容
    extract                # x 命令解压
    docker                 # docker 补全
    npm                    # npm 补全
    node                   # node 补全
)

source $ZSH/oh-my-zsh.sh

# ========== 现代工具替代 ==========
# zoxide - 智能目录跳转
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# eza - 现代化 ls
if command -v eza &> /dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -lah --icons --group-directories-first'
    alias lt='eza --tree --level=2 --icons'
fi

# bat - 现代化 cat
if command -v bat &> /dev/null; then
    alias cat='bat --paging=never'
    alias c='bat'
fi

# fzf - 模糊搜索
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# ========== nvm 配置 ==========
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ========== 别名 ==========
# 常用命令
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# npm
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install -g'
alias nr='npm run'
alias ns='npm start'
alias nt='npm test'

# git
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph'
alias gd='git diff'

# ========== 函数 ==========
# 创建目录并进入
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# 快速 git commit
gac() {
    git add . && git commit -m "$1"
}

# ========== 历史记录 ==========
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS      # 忽略重复命令
setopt HIST_IGNORE_SPACE     # 空格开头的命令不记录
setopt HIST_REDUCE_BLANKS    # 删除多余空格
setopt SHARE_HISTORY         # 多终端共享历史

# ========== 补全设置 ==========
setopt AUTO_MENU             # 按 Tab 多次显示菜单
setopt AUTO_LIST             # 自动列出补全
setopt MENU_COMPLETE         # Tab 循环选择

# ========== 其他设置 ==========
setopt CORRECT               # 命令自动纠正
setopt AUTO_CD               # 输入目录名自动 cd
setopt AUTO_PUSHD            # cd 后自动 pushd
setopt PUSHD_IGNORE_DUPS     # pushd 忽略重复
```

### Oh My Zsh

#### 安装

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 或
sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
```

#### 主题

```bash
# 查看可用主题
ls ~/.oh-my-zsh/themes/

# 编辑 ~/.zshrc
ZSH_THEME="robbyrussell"    # 默认主题
ZSH_THEME="agnoster"        # 流行主题
ZSH_THEME="random"          # 随机主题

# 安装 powerlevel10k(推荐)
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# ~/.zshrc
ZSH_THEME="powerlevel10k/powerlevel10k"

# 配置 powerlevel10k
p10k configure
```

#### 插件

```bash
# 查看可用插件
ls ~/.oh-my-zsh/plugins/

# 安装第三方插件
# zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# zsh-completions
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions

# 启用插件 ~/.zshrc
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
)
```

#### 常用插件说明

| 插件 | 功能 |
|------|------|
| `git` | git 别名和补全 |
| `zsh-autosuggestions` | 根据历史自动建议 |
| `zsh-syntax-highlighting` | 语法高亮 |
| `zsh-completions` | 更多命令补全 |
| `sudo` | 双击 ESC 自动加 sudo |
| `copypath` | `copypath` 复制当前路径 |
| `copyfile` | `copyfile file` 复制文件内容 |
| `extract` | `x archive` 解压任意格式 |
| `web-search` | `google keyword` 打开浏览器搜索 |
| `jsontools` | JSON 格式化工具 |
| `docker` | docker 补全 |
| `npm` | npm 补全 |
| `node` | node 补全 |

### zsh 补全系统

#### 补全行为

```bash
# ~/.zshrc

# 启用补全系统
autoload -Uz compinit && compinit

# 补全样式
zstyle ':completion:*' menu select                          # 菜单选择
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # 大小写不敏感
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"     # 彩色显示
zstyle ':completion:*' group-name ''                        # 分组显示
zstyle ':completion:*' verbose yes                          # 详细描述
```

#### 自定义补全

```bash
# ~/.zshrc

# 补全函数
_my_function() {
    local -a commands
    commands=(
        'start:Start the service'
        'stop:Stop the service'
        'restart:Restart the service'
        'status:Show service status'
    )
    _describe 'command' commands
}

# 注册补全
compdef _my_function mycommand
```

---

## 环境变量管理

### 通用环境变量配置

创建 `~/.profile` (bash 和 zsh 都会读取):

```bash
# ~/.profile
# 通用环境变量配置

# PATH
export PATH="$HOME/.local/bin:$PATH"

# 编辑器
export EDITOR=nvim
export VISUAL=nvim

# 语言
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 其他环境变量
export LESS='-R'
export PAGER=less
```

### 在各 shell 中加载

**~/.bashrc**:
```bash
[[ -f ~/.profile ]] && source ~/.profile
```

**~/.zshenv**:
```bash
[[ -f ~/.profile ]] && source ~/.profile
```

### 环境变量最佳实践

#### 区分 shell 类型

```bash
# ~/.profile 或 ~/.zshenv

# 检测当前 shell
if [ -n "$ZSH_VERSION" ]; then
    # zsh 特定配置
    export ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
elif [ -n "$BASH_VERSION" ]; then
    # bash 特定配置
    export HISTCONTROL=ignoreboth:erasedups
fi
```

#### 按功能分组

```bash
# ========== PATH ==========
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# ========== Node.js ==========
export NVM_DIR="$HOME/.nvm"
export NODE_PATH="/usr/lib/node_modules"

# ========== Python ==========
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# ========== Go ==========
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# ========== Rust ==========
export PATH="$HOME/.cargo/bin:$PATH"

# ========== 编辑器 ==========
export EDITOR=nvim
export VISUAL=nvim

# ========== 语言 ==========
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

### 敏感信息管理

不要在配置文件中硬编码敏感信息:

```bash
# 不推荐 ✗
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# 推荐 ✓ - 使用环境变量文件
# ~/.env
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# ~/.zshrc 或 ~/.bashrc
if [ -f ~/.env ]; then
    export $(grep -v '^#' ~/.env | xargs)
fi

# 推荐 ✓ - 使用工具
# direnv, dotenv, etc.
```

---

## 常见问题

### 问题1: 环境变量在 bash 和 zsh 不同步

**原因**: bash 和 zsh 使用不同的配置文件

**解决方案**:

```bash
# 创建通用配置文件
cat > ~/.profile << 'EOF'
export PATH="$HOME/.local/bin:$PATH"
export EDITOR=nvim
EOF

# 在 ~/.bashrc 中加载
echo '[[ -f ~/.profile ]] && source ~/.profile' >> ~/.bashrc

# 在 ~/.zshenv 中加载
echo '[[ -f ~/.profile ]] && source ~/.profile' >> ~/.zshenv
```

### 问题2: 切换 shell 后 PATH 混乱

**诊断**:

```bash
# 查看 PATH
echo $PATH | tr ':' '\n'

# 查找重复项
echo $PATH | tr ':' '\n' | sort | uniq -d
```

**解决方案**:

```bash
# 在配置文件末尾去重
# ~/.zshrc 或 ~/.bashrc
typeset -U PATH  # zsh
# 或
export PATH=$(echo "$PATH" | tr ':' '\n' | awk '!seen[$0]++' | tr '\n' ':')
```

### 问题3: 全局安装的 npm 包找不到

**原因**: PATH 未包含 npm 全局 bin 目录

**解决方案**:

```bash
# 查看 npm 全局路径
npm config get prefix

# 添加到 PATH
# ~/.zshrc 或 ~/.bashrc
export PATH="$HOME/.npm-global/bin:$PATH"

# 如果使用 nvm,检查 nvm 配置
# ~/.zshrc 或 ~/.bashrc
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

### 问题4: zsh 启动慢

**诊断**:

```bash
# 测量启动时间
time zsh -i -c exit

# 详细分析
zsh -xv 2>&1 | ts -i '%.s' | head -n 20
```

**优化方案**:

```bash
# 1. 延迟加载 nvm
# ~/.zshrc
nvm() {
    unset -f nvm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm "$@"
}

# 2. 减少插件
# 只启用必需的插件
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# 3. 使用更快的主题
ZSH_THEME="robbyrussell"  # 或 "pure"

# 4. 延迟加载 oh-my-zsh
# 使用 zinit 或 zplug 替代

# 5. 禁用自动更新
DISABLE_AUTO_UPDATE="true"
```

### 问题5: 命令别名不生效

**原因**: 别名定义在使用之后,或未重新加载配置

**解决方案**:

```bash
# 重新加载配置
source ~/.zshrc   # 或 source ~/.bashrc

# 检查别名
alias

# 确保别名定义在配置文件中
grep "^alias" ~/.zshrc
```

### 问题6: 历史命令丢失

**bash 解决方案**:

```bash
# ~/.bashrc
shopt -s histappend              # 追加而非覆盖
export PROMPT_COMMAND="history -a; history -n"  # 即时保存
```

**zsh 解决方案**:

```bash
# ~/.zshrc
setopt SHARE_HISTORY             # 多终端共享
setopt APPEND_HISTORY            # 追加历史
setopt INC_APPEND_HISTORY        # 即时追加
```

---

## 最佳实践

### 1. 配置文件结构

```
~/
├── .profile           # 通用环境变量
├── .bashrc            # bash 交互配置
├── .bash_profile      # bash 登录配置(加载 .bashrc)
├── .zshenv            # zsh 环境变量(所有 shell)
├── .zshrc             # zsh 交互配置
└── .zprofile          # zsh 登录配置
```

### 2. 配置文件模板

#### 最小配置 (bash)

```bash
# ~/.bash_profile
[[ -f ~/.bashrc ]] && source ~/.bashrc

# ~/.bashrc
[[ -f ~/.profile ]] && source ~/.profile

export PS1='\u@\h:\w\$ '
alias ll='ls -lah'
```

#### 最小配置 (zsh)

```bash
# ~/.zshenv
export PATH="$HOME/.local/bin:$PATH"
export EDITOR=nvim

# ~/.zshrc
autoload -Uz compinit && compinit
export PROMPT='%n@%m:%~%# '
alias ll='ls -lah'
```

### 3. 配置文件版本控制

```bash
# 创建配置文件仓库
mkdir -p ~/dotfiles
cd ~/dotfiles
git init

# 添加配置文件
ln -s ~/.bashrc ~/dotfiles/bashrc
ln -s ~/.zshrc ~/dotfiles/zshrc
ln -s ~/.profile ~/dotfiles/profile

# 提交
git add .
git commit -m "Add shell configs"
```

### 4. 多机器同步

```bash
# 使用 Git 仓库
git clone https://github.com/yourusername/dotfiles.git
cd dotfiles
./install.sh  # 符号链接到 home 目录

# 或使用工具
# - stow
# - rcm
# - yadm
# - chezmoi
```

### 5. Shell 脚本兼容性

编写兼容 bash 和 zsh 的脚本:

```bash
#!/bin/bash
# 或
#!/bin/sh

# 使用 POSIX 兼容语法
# 避免使用 bash/zsh 特性

# ✓ 兼容
if [ -f "$file" ]; then
    echo "File exists"
fi

# ✗ 不兼容
if [[ -f "$file" ]]; then
    echo "File exists"
fi

# ✓ 数组兼容
set -- "item1" "item2" "item3"
for item in "$@"; do
    echo "$item"
done
```

### 6. 别名命名规范

```bash
# 使用有意义的前缀
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

alias d='docker'
alias dc='docker-compose'
alias dm='docker-machine'

alias n='npm'
alias ni='npm install'
alias nr='npm run'
alias ns='npm start'

# 避免覆盖系统命令
# ✗ 不推荐
# alias ls='exa'
# ✓ 推荐
alias ls='eza --icons'  # 增强而非替换
```

### 7. 函数 vs 别名

```bash
# 别名: 简单命令替换
alias ll='ls -lah'

# 函数: 需要参数或复杂逻辑
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# 函数: 需要条件判断
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "Unknown format" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
```

---

## 快速参考卡片

### 配置文件加载顺序

**bash 登录 shell**:
```
/etc/profile → ~/.bash_profile → ~/.bash_login → ~/.profile
```

**bash 交互式 shell**:
```
/etc/bash.bashrc → ~/.bashrc
```

**zsh 登录 shell**:
```
/etc/zsh/zshenv → ~/.zshenv → /etc/zsh/zprofile → ~/.zprofile → /etc/zsh/zshrc → ~/.zshrc → /etc/zsh/zlogin → ~/.zshlogin
```

**zsh 交互式 shell**:
```
/etc/zsh/zshenv → ~/.zshenv → /etc/zsh/zshrc → ~/.zshrc
```

### 常用命令

```bash
# 查看当前 shell
echo $SHELL
echo $0

# 切换 shell
chsh -s $(which zsh)
chsh -s $(which bash)

# 重新加载配置
source ~/.zshrc
source ~/.bashrc

# 查看环境变量
printenv
echo $PATH

# 查看别名
alias

# 测量启动时间
time zsh -i -c exit
time bash -i -c exit
```

### zsh vs bash 语法差异

```bash
# 数组索引
# bash: 从 0 开始
arr=(a b c)
echo ${arr[0]}  # a

# zsh: 从 1 开始
arr=(a b c)
echo ${arr[1]}  # a

# 通配符
# bash: 基础 glob
ls *.txt

# zsh: 扩展 glob
ls **/*.txt      # 递归匹配
ls *.txt~a*      # 排除 a 开头的文件
ls *(.x0)        # 仅可执行文件

# 字符串分割
# bash
str="a:b:c"
IFS=':' read -ra arr <<< "$str"

# zsh
str="a:b:c"
arr=(${(s/:/)str})
```

---

## 相关资源

- [bash 手册](https://www.gnu.org/software/bash/manual/)
- [zsh 手册](http://zsh.sourceforge.net/Doc/)
- [Oh My Zsh](https://ohmyz.sh/)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [zsh-users 插件](https://github.com/zsh-users)
- [dotfiles 管理](https://dotfiles.github.io/)

---

**最后更新**: 2026-04-07
