# Neovim + LazyVim 编辑器

## 简介

Neovim 是 Vim 的现代化版本，LazyVim 是一套预配置方案，开箱即用。

---

## 安装

已通过 `install-lazyvim.sh` 脚本安装，包含：

- Neovim (>= 0.9)
- LazyVim 配置
- 常用插件和 LSP

---

## 启动

```bash
nvim                # 启动编辑器
nvim 文件名         # 打开单个文件
nvim .              # 打开当前目录
nvim 项目目录       # 打开项目
```

---

## 模式

| 模式 | 进入方式 | 用途 |
|------|----------|------|
| 普通模式 | 默认 / `Esc` | 移动、操作 |
| 插入模式 | `i` / `a` / `o` | 输入文字 |
| 可视模式 | `v` / `V` | 选择文本 |
| 命令模式 | `:` | 执行命令 |

---

## 基本操作

### 移动

| 键 | 功能 |
|----|------|
| `h/j/k/l` | 左/下/上/右 |
| `w` | 下一个单词 |
| `b` | 上一个单词 |
| `0` | 行首 |
| `$` | 行尾 |
| `gg` | 文件开头 |
| `G` | 文件结尾 |
| `Ctrl+d` | 向下翻半页 |
| `Ctrl+u` | 向上翻半页 |

### 编辑

| 键 | 功能 |
|----|------|
| `i` | 在光标前插入 |
| `a` | 在光标后插入 |
| `o` | 在下方新建行插入 |
| `O` | 在上方新建行插入 |
| `dd` | 删除整行 |
| `yy` | 复制整行 |
| `p` | 粘贴 |
| `u` | 撤销 |
| `Ctrl+r` | 重做 |
| `x` | 删除光标字符 |

### 保存退出

| 命令 | 功能 |
|------|------|
| `:w` | 保存 |
| `:q` | 退出 |
| `:wq` | 保存并退出 |
| `:q!` | 强制退出不保存 |
| `ZZ` | 保存并退出 |

---

## LazyVim 快捷键

Leader 键 = `空格`

### 文件操作

| 快捷键 | 功能 |
|--------|------|
| `<Space>ff` | 查找文件 |
| `<Space>fg` | 搜索文件内容 |
| `<Space>fr` | 最近文件 |
| `<Space>fb` | 缓冲区列表 |
| `<Space>e` | 打开文件树 |
| `<Space>E` | 文件树（当前文件） |

### 编辑

| 快捷键 | 功能 |
|--------|------|
| `gd` | 跳转到定义 |
| `gr` | 查找引用 |
| `<Space>ca` | 代码操作（自动修复） |
| `<Space>cr` | 重命名变量 |
| `<Space>cf` | 格式化代码 |
| `K` | 显示文档 |

### 窗口/缓冲区

| 快捷键 | 功能 |
|--------|------|
| `<Space>ww` | 保存 |
| `<Space>wq` | 保存并关闭 |
| `<Space>bd` | 关闭缓冲区 |
| `<Space>bb` | 切换缓冲区 |
| `<C-h/j/k/l>` | 窗口间移动 |

### Git

| 快捷键 | 功能 |
|--------|------|
| `<Space>gg` | 打开 LazyGit |
| `<Space>gb` | Git Blame |
| `]h` / `[h` | 下一个/上一个修改 |

### 终端

| 快捷键 | 功能 |
|--------|------|
| `<Space>ft` | 打开终端 |

---

## 文件树 (neo-tree)

| 键 | 功能 |
|----|------|
| `j/k` | 上下移动 |
| `h` | 折叠目录 / 返回上级 |
| `l` | 展开目录 / 打开文件 |
| `a` | 新建文件/目录 |
| `d` | 删除文件 |
| `r` | 重命名 |
| `c` | 复制文件 |
| `m` | 移动文件 |
| `?` | 显示帮助 |

---

## 学习资源

### 入门教程

```bash
# 在 Neovim 中运行
:Tutor          # 交互式 Vim 教程（约 30 分钟）

# 或直接启动
nvim +Tutor
```

### 练习游戏

```bash
# 在 Neovim 中运行
:VimBeGood      # Vim 操作练习游戏
```

---

## 配置文件

| 文件 | 路径 |
|------|------|
| 主配置 | `~/.config/nvim/init.lua` |
| 插件配置 | `~/.config/nvim/lua/plugins/` |
| 选项配置 | `~/.config/nvim/lua/config/options.lua` |

### 已安装的插件

| 插件 | 功能 |
|------|------|
| `lazyvim.plugins.extras.lang.markdown` | Markdown 支持 |
| `lazyvim.plugins.extras.coding.mini-surround` | 括号操作 |
| `lazyvim.plugins.extras.coding.yanky` | 剪贴板历史 |
| `lazyvim.plugins.extras.editor.inc-rename` | 重命名预览 |
| `lazyvim.plugins.extras.ui.treesitter-context` | 顶部显示当前函数 |

---

## 常见问题

### 添加新语言支持

在 `~/.config/nvim/lua/plugins/` 创建文件：

```lua
-- ~/.config/nvim/lua/plugins/lang.lua
return {
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.json" },
  { import = "lazyvim.plugins.extras.lang.yaml" },
}
```

### 查看插件状态

```bash
# 在 Neovim 中
:Lazy           # 打开插件管理器
```

### 检查健康状态

```bash
# 在 Neovim 中
:checkhealth    # 检查配置和依赖
```

---

## 进阶使用

### Mason (LSP 管理)

```bash
:Mason              # 打开 Mason 界面
:MasonInstall pyright  # 安装 Python LSP
```

### Treesitter (语法高亮)

```bash
:TSInstall python   # 安装 Python 语法高亮
:TSInstallInfo       # 查看已安装的语法
```
