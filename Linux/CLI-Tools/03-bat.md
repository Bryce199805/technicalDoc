# bat 文件查看工具

## 简介

bat 是现代化替代 `cat` 的工具，提供语法高亮、行号、Git 集成等功能。

## 安装

```bash
sudo apt install bat
```

> Ubuntu 下命令名为 `batcat`，已在配置中设置别名为 `bat`。

---

## 已配置的别名

| 命令 | 功能 |
|------|------|
| `cat 文件` | 查看文件（语法高亮，不分页） |
| `c 文件` | 同上 |
| `cl 10:20 文件` | 查看第 10-20 行 |

---

## 基本用法

```bash
# 查看文件
bat file.py

# 显示行号（默认开启）
bat --number file.py

# 不显示行号
bat --style=plain file.py

# 指定语言高亮
bat --language=python file.txt

# 查看指定行
bat --line-range=10:20 file.py

# 同时查看多个文件
bat file1.py file2.py
```

---

## 常用选项

| 选项 | 说明 |
|------|------|
| `-n, --number` | 显示行号 |
| `-A, --show-all` | 显示不可见字符 |
| `--style=STYLE` | 显示样式 |
| `--theme=THEME` | 指定主题 |
| `--list-themes` | 列出所有主题 |
| `-l, --language` | 指定语言 |
| `-r, --line-range` | 显示指定行 |
| `--paging=never` | 禁用分页 |

### style 选项

| 值 | 说明 |
|----|------|
| `auto` | 默认 |
| `full` | 完整（header + grid + numbers） |
| `plain` | 纯文本（无装饰） |
| `header` | 只显示文件头 |
| `grid` | 只显示网格 |
| `numbers` | 只显示行号 |

---

## 查看帮助文档

```bash
# 用 bat 查看 --help 输出（语法高亮）
命令 --help | bathelp

# 例如
python --help | bathelp
```

---

## 主题

列出可用主题：
```bash
bat --list-themes
```

常用主题：
- `Monokai Extended` (默认)
- `TwoDark`
- `GitHub`
- `Solarized (dark)`

设置默认主题（在 `~/.zshrc` 添加）：
```bash
export BAT_THEME="TwoDark"
```

---

## 与其他命令结合

```bash
# 查看代码
rg "pattern" -A 5 | bat -l py

# 查看 JSON
curl -s https://api.github.com | bat -l json

# 查看配置文件
bat ~/.zshrc
```
