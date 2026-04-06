# fzf 模糊搜索

## 简介

fzf (Fuzzy Finder) 是一个命令行模糊搜索工具，用于快速搜索和选择文件、命令、历史记录等。

## 安装

```bash
sudo apt install fzf
```

---

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+R` | 搜索历史命令 |
| `Ctrl+T` | 搜索文件 |
| `Alt+C` | 跳转目录 |

---

## 基本用法

### 搜索历史命令

```
按 Ctrl+R
输入关键词
用 ↑↓ 选择
按 Enter 执行
```

### 搜索文件

```
按 Ctrl+T
输入文件名的一部分
用 ↑↓ 选择
按 Enter 确认
```

### 跳转目录

```
按 Alt+C
输入目录名的一部分
用 ↑↓ 选择
按 Enter 跳转
```

---

## 命令行使用

```bash
# 搜索文件并用 vim 打开
vim $(fzf)

# 搜索文件并列出
ls $(fzf)

# 搜索进程并杀掉
ps aux | fzf | awk '{print $2}' | xargs kill

# 搜索 Git 分支并切换
git checkout $(git branch | fzf)
```

---

## fzf-tab 补全增强

已安装 `fzf-tab` 插件，在 Tab 补全时会用 fzf 界面显示选项。

### 使用方法

```bash
# 输入命令后按 Tab
cd <Tab>           # 显示目录列表，可预览

# 操作
Tab/Shift+Tab      # 下一项/上一项
Ctrl+Space         # 多选
Enter              # 确认
Esc                # 取消
```

### 预览功能

```bash
# 文件补全会显示预览
cat <Tab>          # 显示文件内容预览

# 目录补全会显示内容
cd <Tab>           # 显示目录内容预览

# Git 分支会显示提交信息
git checkout <Tab> # 显示分支和最新提交
```

---

## 自定义配置

在 `~/.zshrc` 中配置：

```bash
# fzf 默认选项
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# 更多选项
export FZF_DEFAULT_OPTS='
  --height 40%
  --layout=reverse
  --border
  --inline-info
  --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9
  --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9
  --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6
  --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4
'
```

---

## 实用技巧

### 搜索文件内容

```bash
# 用 ripgrep 搜索内容，fzf 显示
rg --line-number "" | fzf
```

### 搜索环境变量

```bash
env | fzf
```

### 搜索并执行命令

```bash
# 从历史中选择并编辑
Ctrl+R → 选择 → Ctrl+E（编辑命令）
```

---

## 与其他工具结合

```bash
# fzf + eza
eza | fzf

# fzf + bat（预览文件）
fzf --preview 'bat --style=numbers --color=always {}'

# fzf + git
git log --oneline | fzf
```
