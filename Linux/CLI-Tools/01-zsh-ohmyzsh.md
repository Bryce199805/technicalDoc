# zsh + Oh My Zsh 使用指南

## 什么是 zsh

zsh (Z Shell) 是一个更强大的 Shell，替代默认的 bash，提供更好的交互体验。

### zsh vs bash

| 特性 | bash | zsh |
|------|------|-----|
| 自动补全 | 基础 | 智能菜单选择 |
| 通配符 | 基础 glob | 扩展 glob (`**/*.py`) |
| 插件系统 | 无 | 丰富插件生态 |
| 主题 | 无 | 美观主题 |
| 拼写纠正 | 无 | 自动纠正 |
| 目录跳转 | 必须完整路径 | 支持 `..` `...` `-` |

---

## Oh My Zsh

Oh My Zsh 是 zsh 的配置管理框架，简化主题和插件的管理。

### 已安装的插件

| 插件 | 功能 |
|------|------|
| `git` | git 命令别名和补全 |
| `command-not-found` | 命令未找到时提示安装包 |
| `colored-man-pages` | man 手册彩色显示 |
| `sudo` | 双击 ESC 自动加 sudo |
| `copypath` | 复制当前路径 |
| `copyfile` | 复制文件内容 |
| `extract` | `x` 命令解压任意格式 |
| `zsh-autosuggestions` | 根据历史自动建议（灰色提示） |
| `zsh-syntax-highlighting` | 语法高亮（正确绿色，错误红色） |
| `zsh-completions` | 扩展更多命令的补全规则 |
| `fzf-tab` | 用 fzf 美化补全菜单 |

### 主题

已安装 **powerlevel10k** 主题，首次启动会运行配置向导。

重新配置主题：
```bash
p10k configure
```

---

## 常用快捷键

### 补全

| 操作 | 说明 |
|------|------|
| `Tab` | 补全命令/文件 |
| `Shift+Tab` | 向上选择补全项 |
| `→` (右箭头) | 接受自动建议 |

### 历史搜索

| 操作 | 说明 |
|------|------|
| `Ctrl+R` | 搜索历史命令 |
| `↑` / `↓` | 上一条/下一条历史 |

### 目录跳转

| 操作 | 说明 |
|------|------|
| `..` | 上一级目录 |
| `...` | 上两级目录 |
| `....` | 上三级目录 |
| `-` | 上一个目录 |
| `~` | 家目录 |

### 其他

| 操作 | 说明 |
|------|------|
| `Esc` `Esc` | 自动在命令前加 sudo |
| `Ctrl+L` | 清屏 |
| `Ctrl+A` | 移动到行首 |
| `Ctrl+E` | 移动到行尾 |
| `Ctrl+W` | 删除前一个单词 |
| `Ctrl+U` | 删除整行 |

---

## zoxide 智能跳转

zoxide 会记住你访问过的目录，实现智能跳转。

```bash
# 首次访问目录
z /home/user/projects/my-app

# 之后可以简写跳转
z my-app      # 跳转到 my-app
z ma          # 模糊匹配

# 交互式选择
zi            # 显示列表，方向键选择
```

---

## 配置文件

主配置文件：`~/.zshrc`

编辑配置：
```bash
vim ~/.zshrc
# 或
v ~/.zshrc
```

重新加载配置：
```bash
source ~/.zshrc
```

---

## 添加新插件

1. 克隆插件到 Oh My Zsh 自定义目录：
```bash
git clone https://github.com/作者/插件名 ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/插件名
```

2. 编辑 `~/.zshrc`，在 plugins 中添加：
```bash
plugins=(
    ...
    插件名
)
```

3. 重新加载：
```bash
source ~/.zshrc
```

---

## 常见问题

### 启动慢

插件越多启动越慢。精简 plugins 列表可以加快启动速度。

### 图标显示乱码

需要安装 Nerd Font 字体：
```bash
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/CascadiaCode.zip
unzip CascadiaCode.zip
fc-cache -fv
```

然后在终端设置中将字体改为 **CaskaydiaCove Nerd Font**。
