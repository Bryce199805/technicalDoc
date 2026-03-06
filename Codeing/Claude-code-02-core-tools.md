# Claude Code 核心工具详解

> ⬅️ [上一章：安装与启动](Claude-code-01-install.md) | [返回总览](Claude-code-guild.md) | ➡️ [下一章：交互模式](Claude-code-03-interactive.md)

---

## 目录

- [1. 工具系统概览](#1-工具系统概览)
- [2. Read - 文件读取](#2-read---文件读取)
- [3. Edit - 文件编辑](#3-edit---文件编辑)
- [4. Write - 文件创建与写入](#4-write---文件创建与写入)
- [5. Glob - 文件搜索](#5-glob---文件搜索)
- [6. Grep - 内容搜索](#6-grep---内容搜索)
- [7. Bash - 命令执行](#7-bash---命令执行)
- [8. WebFetch - 网页获取](#8-webfetch---网页获取)
- [9. WebSearch - 网络搜索](#9-websearch---网络搜索)
- [10. NotebookEdit - Jupyter 编辑](#10-notebookedit---jupyter-编辑)
- [11. Agent - 子代理](#11-agent---子代理)
- [12. 工具选择策略](#12-工具选择策略)

---

## 1. 工具系统概览

Claude Code 的核心能力来自于其内置的 **工具系统（Tool System）**。当你向 Claude Code 发出自然语言指令时，它并不是简单地输出文字——而是会**自动分析你的意图**，选择一个或多个合适的工具来完成任务。

### 1.1 工具调用流程

```
用户输入自然语言指令
       │
       ▼
Claude Code 分析意图
       │
       ▼
选择合适的工具（可能同时选择多个）
       │
       ├──▶ 独立任务：并行调用多个工具
       │
       └──▶ 依赖任务：按顺序串行调用
       │
       ▼
执行工具并获取结果
       │
       ▼
基于结果生成回答或继续调用其他工具
```

### 1.2 工具自动选择机制

Claude Code 会根据以下因素自动决定使用哪个工具：

- **任务类型**：读取文件用 Read、搜索文件用 Glob、搜索内容用 Grep
- **上下文信息**：如果你提到了文件路径，优先考虑文件操作类工具
- **效率优先**：优先选择专用工具而非通用的 Bash 工具（例如搜索文件用 Glob 而不是 `find` 命令）
- **安全性**：某些危险操作会自动要求用户确认

### 1.3 并行调用

当多个工具调用之间没有依赖关系时，Claude Code 会**并行执行**以提高效率。例如，当你要求"查看项目结构并读取配置文件"时，Glob 搜索和 Read 读取会同时进行。

---

## 2. Read - 文件读取

Read 是最基础也最常用的工具之一，用于读取本地文件系统中的任何文件。

### 2.1 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `file_path` | string | ✅ | 文件的**绝对路径**（不能是相对路径） |
| `offset` | number | ❌ | 从第几行开始读取（适合大文件） |
| `limit` | number | ❌ | 读取的行数限制（适合大文件） |
| `pages` | string | ❌ | PDF 文件的页码范围，如 `"1-5"`, `"3"`, `"10-20"` |

### 2.2 支持的文件类型

Read 工具功能极为强大，支持多种文件类型：

- **文本文件**：所有代码文件、配置文件、日志文件等
- **图片文件**：PNG、JPG、GIF 等（Claude 是多模态模型，可以"看到"图片内容）
- **PDF 文件**：可读取 PDF 内容，大文件（超过 10 页）**必须**指定 `pages` 参数
- **Jupyter Notebook**：`.ipynb` 文件，返回所有单元格及其输出

### 2.3 使用示例

**读取普通代码文件：**
```
你：请帮我看看 /home/user/project/src/main.py 的内容

Claude Code 内部调用：
Read(file_path="/home/user/project/src/main.py")
```

**读取大文件的特定部分：**
```
你：请看一下日志文件的最后 100 行

Claude Code 内部调用：
Read(file_path="/var/log/app.log", offset=9900, limit=100)
```

**读取 PDF 文件：**
```
你：帮我看看这个文档的前 5 页

Claude Code 内部调用：
Read(file_path="/home/user/docs/report.pdf", pages="1-5")
```

**读取截图进行分析：**
```
你：看一下这个截图，告诉我界面上有什么问题
    路径：/tmp/screenshot.png

Claude Code 内部调用：
Read(file_path="/tmp/screenshot.png")
→ Claude 会以视觉方式分析图片内容
```

### 2.4 注意事项

- 路径**必须**是绝对路径，如 `/home/user/file.txt`，而非 `./file.txt`
- 默认最多读取 **2000 行**，超长行会被截断至 2000 字符
- 输出格式类似 `cat -n`，每行带有行号
- 读取 PDF 时每次请求最多 **20 页**
- 如果文件不存在会返回错误，不会崩溃
- Read 工具**只能读取文件，不能读取目录**（读取目录请用 Bash 的 `ls` 命令）

---

## 3. Edit - 文件编辑

Edit 工具用于对已有文件进行**精确的字符串替换**，是日常代码修改中最常用的工具。

### 3.1 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `file_path` | string | ✅ | 文件的绝对路径 |
| `old_string` | string | ✅ | 要被替换的原始文本 |
| `new_string` | string | ✅ | 替换后的新文本（必须与 old_string 不同） |
| `replace_all` | boolean | ❌ | 是否替换所有匹配项，默认 `false` |

### 3.2 核心规则

**规则一：必须先 Read 再 Edit**

这是一条硬性规则。在对任何文件执行 Edit 之前，必须先用 Read 工具读取过该文件。这确保 Claude Code 了解文件的当前状态，避免盲目修改。

```
❌ 错误做法：直接 Edit 没有读取过的文件
✅ 正确做法：先 Read 文件 → 再 Edit 文件
```

**规则二：old_string 必须唯一**

`old_string` 在文件中必须是**唯一**的。如果同一段文本在文件中出现了多次，Edit 会失败。解决方案：

- 提供更多上下文，包含更多周围代码使其唯一
- 使用 `replace_all: true` 替换所有出现的位置

**规则三：保持精确缩进**

`old_string` 和 `new_string` 中的缩进（空格、制表符）必须与文件中的**完全一致**。

### 3.3 使用示例

**修改函数名称：**
```
你：把 calculate_total 函数改名为 compute_sum

Claude Code 内部调用：
1. Read(file_path="/home/user/project/utils.py")
2. Edit(
     file_path="/home/user/project/utils.py",
     old_string="def calculate_total(items):",
     new_string="def compute_sum(items):"
   )
```

**批量替换变量名（使用 replace_all）：**
```
你：把文件里所有的 userName 改为 user_name

Claude Code 内部调用：
Edit(
  file_path="/home/user/project/app.js",
  old_string="userName",
  new_string="user_name",
  replace_all=true
)
```

**添加新的导入语句：**
```
你：在文件顶部的导入区域加上 import json

Claude Code 内部调用：
Edit(
  file_path="/home/user/project/main.py",
  old_string="import os\nimport sys",
  new_string="import os\nimport sys\nimport json"
)
```

**修复一个 Bug（需要足够上下文来保证唯一性）：**
```
Claude Code 内部调用：
Edit(
  file_path="/home/user/project/handler.py",
  old_string="    if user.age > 18:\n        return True",
  new_string="    if user.age >= 18:\n        return True"
)
```

### 3.4 Edit vs Write 的选择

| 场景 | 推荐工具 |
|------|----------|
| 修改文件中的一小段内容 | **Edit** ✅ |
| 重命名变量 | **Edit**（配合 replace_all）✅ |
| 创建一个全新的文件 | **Write** ✅ |
| 对文件进行大规模重写 | **Write**（但需先 Read）✅ |

---

## 4. Write - 文件创建与写入

Write 工具用于创建新文件或**完全覆盖**已有文件的全部内容。

### 4.1 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `file_path` | string | ✅ | 文件的绝对路径（必须是绝对路径） |
| `content` | string | ✅ | 要写入的完整文件内容 |

### 4.2 使用规则

- 如果目标路径已有文件，Write 会**完全覆盖**该文件
- 覆盖已有文件之前**必须先 Read** 该文件
- 创建全新文件则不需要先 Read
- **优先使用 Edit 而非 Write** —— Edit 只发送差异部分，效率更高
- 不会自动创建 Markdown 文档或 README 文件（除非用户明确要求）

### 4.3 使用示例

**创建新的配置文件：**
```
你：帮我创建一个 .eslintrc.json 配置文件

Claude Code 内部调用：
Write(
  file_path="/home/user/project/.eslintrc.json",
  content='{\n  "env": {\n    "browser": true,\n    "es2021": true\n  },\n  "extends": "eslint:recommended",\n  "rules": {\n    "indent": ["error", 2],\n    "quotes": ["error", "double"]\n  }\n}'
)
```

**创建新的 Python 脚本：**
```
你：在 scripts 目录下创建一个数据清洗脚本

Claude Code 内部调用：
1. Bash(command="ls /home/user/project/scripts/")  # 确认目录存在
2. Write(
     file_path="/home/user/project/scripts/clean_data.py",
     content="import pandas as pd\n\ndef clean_data(input_path, output_path):\n    df = pd.read_csv(input_path)\n    df = df.dropna()\n    df = df.drop_duplicates()\n    df.to_csv(output_path, index=False)\n    print(f'Cleaned data saved to {output_path}')\n\nif __name__ == '__main__':\n    clean_data('raw_data.csv', 'clean_data.csv')\n"
   )
```

### 4.4 典型使用场景

1. **创建全新文件** —— 新的源代码文件、配置文件、脚本等
2. **完全重写文件** —— 当修改量超过 50% 时，Write 比多次 Edit 更高效
3. **生成模板文件** —— Dockerfile、CI 配置、项目脚手架文件等

---

## 5. Glob - 文件搜索

Glob 工具是快速的文件名模式匹配工具，用于在项目中按名称模式查找文件。

### 5.1 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `pattern` | string | ✅ | glob 匹配模式，如 `"**/*.js"` |
| `path` | string | ❌ | 搜索的根目录，默认为当前工作目录 |

### 5.2 Glob 语法详解

Glob 模式使用特殊通配符来匹配文件路径：

| 通配符 | 含义 | 示例 |
|--------|------|------|
| `*` | 匹配当前目录中的任意字符（不跨目录） | `*.js` → 当前目录所有 JS 文件 |
| `**` | 递归匹配任意层级的目录 | `**/*.js` → 所有子目录中的 JS 文件 |
| `?` | 匹配单个任意字符 | `file?.txt` → file1.txt, fileA.txt |
| `{a,b}` | 匹配 a 或 b | `*.{ts,tsx}` → 所有 TS 和 TSX 文件 |
| `[abc]` | 匹配方括号中的任意一个字符 | `file[123].txt` → file1.txt 等 |

### 5.3 使用示例

**查找项目中所有的 Python 文件：**
```
你：这个项目里有哪些 Python 文件？

Claude Code 内部调用：
Glob(pattern="**/*.py", path="/home/user/project")
```

**查找特定目录下的配置文件：**
```
你：看看 config 目录下有哪些 YAML 配置

Claude Code 内部调用：
Glob(pattern="config/**/*.{yml,yaml}")
```

**查找所有测试文件：**
```
你：找到所有的测试文件

Claude Code 内部调用：
Glob(pattern="**/*test*.{py,js,ts}")
Glob(pattern="**/*spec*.{js,ts}")   # 可能并行调用多个模式
```

**查找特定命名模式的文件：**
```
你：有没有以 index 开头的文件？

Claude Code 内部调用：
Glob(pattern="**/index.*")
```

### 5.4 注意事项

- 返回的结果按**修改时间排序**
- 适合任何规模的代码库，性能优异
- 应该用 Glob 替代 Bash 中的 `find` 命令来搜索文件
- 如果需要在搜索结果中进一步筛选文件内容，应配合 Grep 使用

---

## 6. Grep - 内容搜索

Grep 是基于 **ripgrep（rg）** 的强大内容搜索工具，支持正则表达式，是在代码中搜索特定内容的首选工具。

### 6.1 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `pattern` | string | ✅ | 正则表达式搜索模式 |
| `path` | string | ❌ | 搜索路径，默认当前工作目录 |
| `glob` | string | ❌ | 文件名过滤，如 `"*.js"` |
| `type` | string | ❌ | 文件类型过滤，如 `"py"`, `"js"`, `"rust"` |
| `output_mode` | string | ❌ | 输出模式（详见下方） |
| `context` / `-C` | number | ❌ | 显示匹配行前后各 N 行上下文 |
| `-A` | number | ❌ | 显示匹配行后面 N 行 |
| `-B` | number | ❌ | 显示匹配行前面 N 行 |
| `-i` | boolean | ❌ | 大小写不敏感搜索 |
| `-n` | boolean | ❌ | 显示行号（默认 true） |
| `multiline` | boolean | ❌ | 多行匹配模式，允许 `.` 匹配换行符 |
| `head_limit` | number | ❌ | 限制输出的条目数量 |
| `offset` | number | ❌ | 跳过前 N 条结果 |

### 6.2 三种输出模式

| 模式 | 说明 | 适用场景 |
|------|------|----------|
| `files_with_matches` | 仅返回匹配的文件路径（**默认**） | 快速定位哪些文件包含目标内容 |
| `content` | 返回匹配的行及内容 | 查看具体匹配内容和上下文 |
| `count` | 返回每个文件的匹配次数 | 统计分析，了解使用频率 |

### 6.3 使用示例

**搜索函数定义：**
```
你：帮我找到 handleSubmit 函数在哪里定义的

Claude Code 内部调用：
Grep(
  pattern="function handleSubmit|const handleSubmit|def handleSubmit",
  output_mode="content",
  type="js",
  -n=true
)
```

**搜索 TODO 注释：**
```
你：项目中有哪些 TODO 待处理？

Claude Code 内部调用：
Grep(
  pattern="TODO|FIXME|HACK",
  output_mode="content",
  context=1
)
```

**在特定文件类型中搜索（不区分大小写）：**
```
你：在 Python 文件中找所有用到 requests 库的地方

Claude Code 内部调用：
Grep(
  pattern="import requests|from requests",
  type="py",
  output_mode="content"
)
```

**使用正则表达式搜索复杂模式：**
```
你：找到所有 API 端点定义

Claude Code 内部调用：
Grep(
  pattern="@(app|router)\.(get|post|put|delete|patch)\\(",
  type="py",
  output_mode="content",
  -A=2
)
```

**多行匹配（搜索跨行的内容）：**
```
你：找到所有包含空 try-except 的代码块

Claude Code 内部调用：
Grep(
  pattern="try:[\\s\\S]*?except.*:\\s*pass",
  type="py",
  multiline=true,
  output_mode="content"
)
```

**统计匹配数量：**
```
你：每个文件里分别用了多少次 console.log？

Claude Code 内部调用：
Grep(
  pattern="console\\.log",
  type="js",
  output_mode="count"
)
```

### 6.4 注意事项

- **永远使用 Grep 工具而不是 Bash 中的 `grep` 或 `rg` 命令**
- 使用 ripgrep 语法，而非传统 grep 语法（例如字面花括号需要转义：`interface\{\}`）
- `type` 参数比 `glob` 参数在过滤标准文件类型时更高效
- 默认情况下模式在单行内匹配，跨行搜索需要设置 `multiline: true`
- 如果只需要知道"哪些文件"包含内容，用默认的 `files_with_matches` 模式最高效

---

## 7. Bash - 命令执行

Bash 工具是最通用的工具，可以执行任何 shell 命令。但正因为它的通用性，在有专用工具可用时应**优先使用专用工具**。

### 7.1 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `command` | string | ✅ | 要执行的 shell 命令 |
| `description` | string | ❌ | 命令的简短描述（便于用户理解） |
| `timeout` | number | ❌ | 超时时间（毫秒），最大 600000（10 分钟），默认 120000（2 分钟） |
| `run_in_background` | boolean | ❌ | 是否后台运行，默认 false |

### 7.2 工作目录

Bash 工具的工作目录在命令之间**持久化**——即上一个命令中 `cd` 进入的目录在下一个命令中仍然有效。但 shell 状态（如环境变量、别名）**不会**在命令之间保持。

### 7.3 使用示例

**运行项目构建：**
```
你：帮我构建项目

Claude Code 内部调用：
Bash(
  command="npm run build",
  description="Build the project",
  timeout=300000
)
```

**安装依赖：**
```
你：安装 axios 库

Claude Code 内部调用：
Bash(
  command="npm install axios",
  description="Install axios package"
)
```

**运行测试：**
```
你：跑一下单元测试

Claude Code 内部调用：
Bash(
  command="pytest tests/ -v",
  description="Run unit tests with verbose output"
)
```

**后台运行长时间任务：**
```
你：启动开发服务器

Claude Code 内部调用：
Bash(
  command="npm run dev",
  description="Start development server",
  run_in_background=true
)
→ 服务器在后台启动，Claude Code 不会等待它结束
→ 任务完成时会收到通知
```

**Git 操作：**
```
你：看看 git 状态

Claude Code 内部调用：
Bash(command="git status", description="Show working tree status")
Bash(command="git log --oneline -10", description="Show recent 10 commits")
# 这两个命令会并行执行
```

**链式命令：**
```
你：创建目录并初始化项目

Claude Code 内部调用：
Bash(
  command="mkdir -p /home/user/new-project && cd /home/user/new-project && npm init -y",
  description="Create directory and initialize npm project"
)
```

### 7.4 安全限制与最佳实践

**文件路径引号：**
```bash
# 包含空格的路径必须加双引号
cd "/path/with spaces/directory"
```

**优先使用专用工具：**

| 任务 | ❌ 不推荐（Bash） | ✅ 推荐（专用工具） |
|------|-------------------|---------------------|
| 搜索文件 | `find . -name "*.py"` | Glob |
| 搜索内容 | `grep -r "pattern" .` | Grep |
| 读取文件 | `cat file.txt` | Read |
| 编辑文件 | `sed -i 's/old/new/g'` | Edit |
| 写入文件 | `echo "content" > file` | Write |

**Git 操作安全规范：**
- 不要执行 `git push --force`、`git reset --hard`、`git checkout .` 等破坏性命令（除非用户明确要求）
- 提交代码时优先创建新提交，而非 `--amend` 修改上一个提交
- 不要跳过 git hooks（不使用 `--no-verify`）
- 不要修改 git config

**避免不必要的 sleep：**
- 不要在命令之间添加 sleep
- 长时间任务使用 `run_in_background` 而非 sleep 轮询
- 需要轮询时使用检查命令（如 `gh run view`）而非 sleep

### 7.5 超时处理

默认超时 2 分钟（120000ms），最长可设置 10 分钟（600000ms）。对于编译、测试等可能耗时较长的操作，建议手动设置较大的 timeout 值。

---

## 8. WebFetch - 网页获取

WebFetch 工具用于获取指定 URL 的内容，并用 AI 模型对内容进行分析处理。

### 8.1 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `url` | string | ✅ | 要获取内容的完整 URL |
| `prompt` | string | ✅ | 用于分析获取内容的提示语 |

### 8.2 工作原理

```
URL 输入 → 获取网页内容 → HTML 转 Markdown → AI 模型分析 → 返回结果
```

### 8.3 特性

- **HTML 转 Markdown**：自动将网页内容转换为 Markdown 格式，方便处理
- **15 分钟缓存**：重复访问同一 URL 时会使用缓存，加速响应
- **自动 HTTPS**：HTTP 链接会自动升级为 HTTPS
- **重定向处理**：当 URL 重定向到不同主机时，工具会通知并提供重定向 URL
- **内容摘要**：如果内容过大，会自动摘要

### 8.4 使用示例

**查阅 API 文档：**
```
你：帮我看一下 FastAPI 官方文档中关于依赖注入的部分

Claude Code 内部调用：
WebFetch(
  url="https://fastapi.tiangolo.com/tutorial/dependencies/",
  prompt="提取关于 FastAPI 依赖注入的核心概念、用法示例和最佳实践"
)
```

**分析竞品页面：**
```
你：看看这个产品页面有哪些功能特性

Claude Code 内部调用：
WebFetch(
  url="https://example.com/product",
  prompt="列出此产品页面展示的所有主要功能和特性"
)
```

**获取 API 响应说明：**
```
你：看看这个 API 端点的文档

Claude Code 内部调用：
WebFetch(
  url="https://api.example.com/docs",
  prompt="提取 API 端点列表、请求参数和响应格式"
)
```

### 8.5 注意事项

- URL 必须是完整的合法 URL
- 对于 GitHub 相关的 URL，推荐使用 `gh` CLI 命令代替 WebFetch
- 此工具为**只读**操作，不会修改任何文件
- 如果有 MCP 提供的 web fetch 工具可用，优先使用 MCP 工具

---

## 9. WebSearch - 网络搜索

WebSearch 工具可以在网络上搜索信息，为 Claude Code 提供实时、最新的信息补充。

### 9.1 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `query` | string | ✅ | 搜索关键词（至少 2 个字符） |
| `allowed_domains` | string[] | ❌ | 只包含这些域名的结果 |
| `blocked_domains` | string[] | ❌ | 排除这些域名的结果 |

### 9.2 使用示例

**搜索技术文档：**
```
你：最新版 React 19 有什么新特性？

Claude Code 内部调用：
WebSearch(
  query="React 19 new features 2026"
)
```

**限定域名搜索：**
```
你：在 MDN 上搜一下 Promise.allSettled 的用法

Claude Code 内部调用：
WebSearch(
  query="Promise.allSettled usage",
  allowed_domains=["developer.mozilla.org"]
)
```

**排除特定域名：**
```
你：搜索 Python asyncio 教程，不要 CSDN 的

Claude Code 内部调用：
WebSearch(
  query="Python asyncio tutorial",
  blocked_domains=["csdn.net"]
)
```

### 9.3 注意事项

- 搜索结果会包含链接，Claude Code 会在回答末尾附上来源（Sources）
- 搜索查询中应使用当前年份以获取最新信息
- 仅在美国可用
- 适合获取 Claude 知识截止日期之后的最新信息

---

## 10. NotebookEdit - Jupyter 编辑

NotebookEdit 用于编辑 Jupyter Notebook（`.ipynb`）文件中的单元格。

### 10.1 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `notebook_path` | string | ✅ | Notebook 的绝对路径 |
| `new_source` | string | ✅ | 单元格的新内容 |
| `cell_number` | number | ❌ | 单元格编号（0 索引） |
| `cell_id` | string | ❌ | 单元格 ID（插入时为插入位置之后的单元格 ID） |
| `cell_type` | string | ❌ | 单元格类型：`"code"` 或 `"markdown"` |
| `edit_mode` | string | ❌ | 编辑模式：`"replace"`（默认）、`"insert"`、`"delete"` |

### 10.2 三种编辑模式

| 模式 | 说明 |
|------|------|
| `replace` | 替换指定单元格的内容（默认） |
| `insert` | 在指定位置插入新单元格 |
| `delete` | 删除指定位置的单元格 |

### 10.3 使用示例

**替换某个代码单元格的内容：**
```
你：把第三个单元格改成用 matplotlib 画图

Claude Code 内部调用：
1. Read(file_path="/home/user/analysis.ipynb")  # 先读取 notebook
2. NotebookEdit(
     notebook_path="/home/user/analysis.ipynb",
     cell_number=2,         # 0 索引，第三个单元格
     new_source="import matplotlib.pyplot as plt\n\nplt.figure(figsize=(10, 6))\nplt.plot(x_data, y_data)\nplt.title('Data Visualization')\nplt.xlabel('X')\nplt.ylabel('Y')\nplt.show()",
     cell_type="code",
     edit_mode="replace"
   )
```

**插入新的 Markdown 说明单元格：**
```
你：在第二个单元格后面加一段说明文字

Claude Code 内部调用：
NotebookEdit(
  notebook_path="/home/user/analysis.ipynb",
  cell_number=2,
  new_source="## 数据预处理\n\n以下步骤对原始数据进行清洗和转换：\n- 去除缺失值\n- 标准化数值特征\n- 编码分类变量",
  cell_type="markdown",
  edit_mode="insert"
)
```

**删除多余的单元格：**
```
你：删掉第五个单元格，那个不需要了

Claude Code 内部调用：
NotebookEdit(
  notebook_path="/home/user/analysis.ipynb",
  cell_number=4,
  new_source="",
  edit_mode="delete"
)
```

---

## 11. Agent - 子代理

Agent 工具允许 Claude Code 启动一个**子代理（Sub-agent）** 来处理需要独立探索的复杂子任务。

### 11.1 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `prompt` | string | ✅ | 交给子代理的任务描述 |
| `description` | string | ❌ | 任务的简短描述 |
| `subagent_type` | string | ❌ | 子代理类型（见下方） |
| `run_in_background` | boolean | ❌ | 是否后台运行 |
| `isolation` | boolean | ❌ | 是否在隔离环境中运行 |

### 11.2 子代理类型

| 类型 | 说明 | 适用场景 |
|------|------|----------|
| `general-purpose` | 通用子代理 | 各类通用任务 |
| `Explore` | 探索型子代理 | 代码库探索、文件结构分析 |
| `Plan` | 规划型子代理 | 制定实施计划、架构设计 |

### 11.3 使用示例

**探索一个不熟悉的代码库：**
```
你：帮我深入了解这个项目的架构

Claude Code 内部调用：
Agent(
  prompt="探索 /home/user/project 的项目结构，分析主要模块、依赖关系和架构模式。重点关注：1) 目录结构 2) 核心模块 3) 数据流 4) 使用的框架和库",
  description="探索项目架构",
  subagent_type="Explore"
)
```

**制定重构计划：**
```
你：这个模块需要重构，帮我制定一个计划

Claude Code 内部调用：
Agent(
  prompt="分析 /home/user/project/src/legacy 模块的代码质量问题，并制定详细的重构计划。包括：1) 现有问题清单 2) 重构步骤 3) 风险评估 4) 测试策略",
  description="制定重构计划",
  subagent_type="Plan"
)
```

**后台并行处理多个子任务：**
```
你：同时分析前端和后端的代码质量

Claude Code 内部调用：
Agent(
  prompt="分析 /home/user/project/frontend 的前端代码质量",
  description="前端代码分析",
  run_in_background=true
)
Agent(
  prompt="分析 /home/user/project/backend 的后端代码质量",
  description="后端代码分析",
  run_in_background=true
)
# 两个子代理在后台并行运行
```

### 11.4 子代理 vs 直接操作

| 场景 | 推荐方式 |
|------|----------|
| 简单的文件读取/修改 | 直接使用 Read/Edit |
| 需要多轮搜索和探索的复杂任务 | Agent（Explore 类型） |
| 需要制定多步骤计划 | Agent（Plan 类型） |
| 多个独立子任务需要并行 | Agent（run_in_background） |

---

## 12. 工具选择策略

### 12.1 决策树

在面对任务时，按以下优先级选择工具：

```
需要做什么？
│
├─ 读取文件内容？
│  └─▶ Read
│
├─ 搜索文件（按文件名）？
│  └─▶ Glob
│
├─ 搜索内容（按文件内容）？
│  └─▶ Grep
│
├─ 修改现有文件的一部分？
│  └─▶ Edit（需先 Read）
│
├─ 创建新文件或完全重写？
│  └─▶ Write
│
├─ 编辑 Jupyter Notebook？
│  └─▶ NotebookEdit
│
├─ 获取网页内容？
│  └─▶ WebFetch
│
├─ 搜索最新信息？
│  └─▶ WebSearch
│
├─ 复杂的探索/规划任务？
│  └─▶ Agent
│
└─ 其他（运行命令、构建、测试、Git 等）？
   └─▶ Bash
```

### 12.2 常见错误用法

| ❌ 错误 | ✅ 正确 | 原因 |
|---------|---------|------|
| 用 Bash `cat` 读取文件 | 用 Read 读取文件 | Read 提供更好的格式和行号 |
| 用 Bash `grep` 搜索内容 | 用 Grep 搜索内容 | Grep 工具有权限优化，支持更多参数 |
| 用 Bash `find` 搜索文件 | 用 Glob 搜索文件 | Glob 性能更好，结果按修改时间排序 |
| 用 Bash `sed` 修改文件 | 用 Edit 修改文件 | Edit 更安全，有唯一性检查 |
| 用 Bash `echo >` 创建文件 | 用 Write 创建文件 | Write 更可靠，有覆盖保护 |
| 对小改动使用 Write | 使用 Edit | Edit 只发送差异，效率更高 |
| 没 Read 就 Edit | 先 Read 再 Edit | 不读取就无法确保匹配正确 |
| 用 Grep 搜索文件名 | 用 Glob 搜索文件名 | Grep 搜索文件内容，Glob 搜索文件名 |

### 12.3 工具组合最佳实践

**实践一：探索 → 理解 → 修改**
```
1. Glob   → 找到相关文件
2. Grep   → 定位具体代码位置
3. Read   → 理解代码上下文
4. Edit   → 进行精确修改
5. Bash   → 运行测试验证
```

**实践二：并行探索**
```
同时执行多个独立搜索：
- Glob("**/*.py")         # 找 Python 文件
- Grep("import torch")    # 找 PyTorch 相关代码
- Read("requirements.txt") # 查看依赖
```

**实践三：创建 + 验证**
```
1. Write  → 创建新文件
2. Bash   → 运行 linter/formatter 检查
3. Edit   → 修复发现的问题
4. Bash   → 再次验证
```

**实践四：信息收集**
```
1. WebSearch  → 搜索最新信息
2. WebFetch   → 获取具体页面内容
3. 综合分析   → 基于收集的信息回答问题
```

### 12.4 性能优化提示

1. **并行调用**：独立的工具调用应尽量并行执行
2. **精确搜索**：Grep 中使用 `type` 参数比 `glob` 参数更高效
3. **按需读取**：大文件使用 `offset` 和 `limit` 只读取需要的部分
4. **选对输出模式**：Grep 的 `files_with_matches` 比 `content` 更快
5. **后台运行**：长时间的 Bash 命令使用 `run_in_background`

---

## 小结

Claude Code 的工具系统是其强大能力的基石。理解每个工具的特点和适用场景，能帮助你更高效地与 Claude Code 协作：

| 工具 | 一句话总结 |
|------|-----------|
| **Read** | 读取任何文件（代码、图片、PDF、Notebook） |
| **Edit** | 精确替换文件中的特定文本 |
| **Write** | 创建新文件或完全重写文件 |
| **Glob** | 按文件名模式快速查找文件 |
| **Grep** | 按内容在文件中搜索（正则支持） |
| **Bash** | 执行任意 shell 命令 |
| **WebFetch** | 获取并分析网页内容 |
| **WebSearch** | 搜索网络获取最新信息 |
| **NotebookEdit** | 编辑 Jupyter Notebook 单元格 |
| **Agent** | 启动子代理处理复杂子任务 |

掌握这些工具，你就掌握了与 Claude Code 深度协作的钥匙。

---

> ⬅️ [上一章：安装与启动](Claude-code-01-install.md) | [返回总览](Claude-code-guild.md) | ➡️ [下一章：交互模式](Claude-code-03-interactive.md)
