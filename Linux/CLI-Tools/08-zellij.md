# Zellij 终端复用

## 简介

Zellij 是现代化的终端复用器，用于分屏、会话管理等。比 tmux 更易用，开箱即用。

## 安装

```bash
sudo apt install zellij
```

---

## 基本用法

### 启动

```bash
zellij              # 启动新会话
zellij -s 名称      # 启动命名会话
zellij attach 名称  # 恢复会话
zellij list-sessions  # 列出所有会话
```

### 退出

| 操作 | 说明 |
|------|------|
| `Ctrl+q` | 退出 Zellij |
| `Ctrl+d` | 分离会话（后台运行） |

---

## 界面说明

```
┌─────────────────────────────────────────────────────────────┐
│  ZELLIJ | SESSION: main | MODE: NORMAL                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   $ vim app.py                                             │
│   ...                                                       │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│   $ python server.py                                       │
│   * Running on http://localhost:5000                       │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  Ctrl+p > d: split down | Ctrl+t > n: new tab | Ctrl+q: quit│
└─────────────────────────────────────────────────────────────┘
```

底部状态栏会显示可用快捷键提示。

---

## 模式操作

Zellij 有多种模式，通过前缀键进入：

### 面板模式 (Ctrl+p)

| 操作 | 功能 |
|------|------|
| `Ctrl+p → d` | 垂直分屏（向下） |
| `Ctrl+p → e` | 水平分屏（向右） |
| `Ctrl+p → x` | 关闭当前面板 |
| `Ctrl+p → h/j/k/l` | 切换面板（左/下/上/右） |
| `Ctrl+p → w` | 切换浮动面板 |
| `Ctrl+p → f` | 全屏当前面板 |
| `Ctrl+p → +` | 增大面板 |
| `Ctrl+p → -` | 缩小面板 |

### 标签模式 (Ctrl+t)

| 操作 | 功能 |
|------|------|
| `Ctrl+t → n` | 新建标签 |
| `Ctrl+t → x` | 关闭当前标签 |
| `Ctrl+t → h/l` | 切换标签 |

### 会话模式

| 操作 | 功能 |
|------|------|
| `Ctrl+d` | 分离会话 |
| `Ctrl+q` | 退出 Zellij |

---

## 快捷键速查

### 分屏

```
Ctrl+p → d    垂直分屏
Ctrl+p → e    水平分屏
Ctrl+p → x    关闭面板
```

### 切换

```
Ctrl+p → h    切换到左边面板
Ctrl+p → l    切换到右边面板
Ctrl+p → j    切换到下边面板
Ctrl+p → k    切换到上边面板
Ctrl+t → h    切换到上一个标签
Ctrl+t → l    切换到下一个标签
```

### 标签

```
Ctrl+t → n    新建标签
Ctrl+t → x    关闭标签
```

---

## 会话管理

```bash
# 创建命名会话
zellij -s dev

# 分离会话（在 Zellij 内按 Ctrl+d）

# 列出会话
zellij list-sessions

# 恢复会话
zellij attach dev

# 杀死会话
zellij kill-session dev
```

---

## 配置文件

配置文件位置：`~/.config/zellij/config.kdl`

创建配置：
```bash
mkdir -p ~/.config/zellij
zellij setup --dump-config > ~/.config/zellij/config.kdl
```

常用配置：

```kdl
// 主题
theme "catppuccin-mocha"

// 默认 Shell
default_shell "zsh"

// 默认布局
default_layout "compact"

// 面板边框
pane_frames false

// 鼠标支持
mouse_mode true
```

---

## 与 tmux 对比

| 特性 | tmux | Zellij |
|------|------|--------|
| 配置 | 需要写配置文件 | 开箱即用 |
| 快捷键 | 需要记忆 | 底部有提示 |
| 状态栏 | 基础 | 丰富 |
| 插件 | 有 | 现代插件系统 |
| 鼠标支持 | 需配置 | 默认支持 |

---

## 实用场景

### SSH 远程开发

```bash
# SSH 连接后启动 Zellij
ssh user@server
zellij -s dev

# 开始工作...
vim code.py
python app.py

# 网络断了也没事，会话还在后台

# 重新连接后恢复
ssh user@server
zellij attach dev
```

### 分屏工作流

```bash
zellij

# Ctrl+p → d 分屏
# 上方：vim 编辑代码
# 下方：python 运行代码

# Ctrl+p → e 再分屏
# 下方左边：python 运行
# 下方右边：git 操作
```
