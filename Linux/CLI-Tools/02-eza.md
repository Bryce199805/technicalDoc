# eza 文件列表工具

## 简介

eza 是现代化替代 `ls` 的工具，提供彩色输出、图标、Git 状态等功能。

## 安装

```bash
sudo apt install eza
```

## 基本用法

```bash
eza                 # 列出文件（带图标）
eza -l              # 详细列表
eza -la             # 详细列表（含隐藏文件）
eza --tree          # 树形显示
eza --tree --level=3  # 树形显示（3层）
```

---

## 已配置的别名

| 命令 | 实际命令 | 功能 |
|------|----------|------|
| `ls` | `eza --icons --group-directories-first` | 基础列表 |
| `l` | `eza -l --icons --group-directories-first` | 详细列表（不含隐藏） |
| `ll` | `eza -la --icons --group-directories-first` | 详细列表（含隐藏） |
| `lt` | `eza -l --sort=modified --icons` | 按修改时间排序 |
| `lS` | `eza -l --sort=size --icons` | 按大小排序 |
| `t` | `eza --tree --level=2 --icons` | 树形显示（2层） |
| `tt` | `eza --tree --level=3 --icons` | 树形显示（3层） |
| `ta` | `eza --tree --level=3 --icons --all` | 树形显示（含隐藏） |

---

## 常用选项

### 排序

| 选项 | 说明 |
|------|------|
| `--sort=name` | 按名称排序（默认） |
| `--sort=size` | 按大小排序 |
| `--sort=modified` | 按修改时间排序 |
| `--sort=created` | 按创建时间排序 |
| `--sort=extension` | 按扩展名排序 |
| `--sort=gitstatus` | 按 Git 状态排序 |

### 显示

| 选项 | 说明 |
|------|------|
| `-l` | 详细列表 |
| `-a` | 显示隐藏文件 |
| `--tree` | 树形显示 |
| `--level=N` | 树形层级 |
| `--icons` | 显示图标 |
| `--git` | 显示 Git 状态 |
| `--group-directories-first` | 目录优先 |

### 过滤

| 选项 | 说明 |
|------|------|
| `-d` | 只显示目录 |
| `-f` | 只显示文件 |
| `--ext=txt` | 只显示指定扩展名 |

---

## Git 状态图标

| 图标 | 含义 |
|------|------|
| `N` | 新文件 |
| `M` | 已修改 |
| `D` | 已删除 |
| `R` | 已重命名 |
| `?` | 未跟踪 |

---

## 示例

```bash
# 查看当前目录
l

# 查看所有文件（含隐藏）
ll

# 按时间排序查看最近修改
lt

# 查看目录结构
t

# 查看更深层级
tt

# 查看 Git 状态
eza -la --git
```
