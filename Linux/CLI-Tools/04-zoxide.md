# zoxide 智能目录跳转

## 简介

zoxide 是一个智能目录跳转工具，记住你常访问的目录，实现快速跳转。

## 安装

```bash
sudo apt install zoxide
```

## 初始化

在 `~/.zshrc` 中已配置：
```bash
eval "$(zoxide init zsh)"
```

---

## 基本用法

### z - 智能跳转

```bash
# 首次访问目录（会自动记住）
cd /home/user/projects/my-app

# 之后可以简写跳转
z my-app          # 跳转到 my-app
z ma              # 模糊匹配，跳转到包含 "ma" 的最常用目录
z p ma            # 跳转到 projects 下的 ma
```

### zi - 交互式选择

```bash
zi                # 显示所有记住的目录，用 fzf 选择
```

---

## 工作原理

1. 每次使用 `cd` 或 `z` 访问目录，zoxide 会记录
2. 访问越频繁的目录，排名越高
3. 使用模糊匹配，不需要输入完整路径

---

## 常用命令

| 命令 | 说明 |
|------|------|
| `z 目录` | 跳转到匹配的目录 |
| `zi` | 交互式选择目录 |
| `z -l` | 列出所有记住的目录 |

---

## 示例

```bash
# 访问一些目录
cd /home/user/projects/frontend
cd /home/user/projects/backend
cd /home/user/documents/notes

# 现在可以快速跳转
z front          # 跳转到 frontend
z back           # 跳转到 backend
z note           # 跳转到 notes

# 交互式选择
zi               # 显示列表，选择跳转
```

---

## 与 cd 的区别

| cd | zoxide |
|----|--------|
| 需要完整路径或相对路径 | 只需部分匹配 |
| 不记住历史 | 记住访问频率 |
| `cd ../../project` | `z proj` |

---

## 进阶用法

```bash
# 跳转到上级目录中匹配的
z ..

# 列出所有目录
z -l

# 查看得分
z -l -s
```

---

## 数据存储

zoxide 的数据存储在 `~/.local/share/zoxide/` 目录。

清除数据：
```bash
rm -rf ~/.local/share/zoxide/
```
