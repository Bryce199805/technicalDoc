# Claude Code MCP 服务器与 Hooks

> ⬅️ [上一章：子代理与Skills](Claude-code-06-agents.md) | [返回总览](Claude-code-guild.md) | ➡️ [下一章：实战工作流](Claude-code-08-workflows.md)

---

## 一、MCP 协议简介

### 1.1 什么是 Model Context Protocol (MCP)

**Model Context Protocol（模型上下文协议）** 是 Anthropic 推出的一套开放标准协议，旨在为 AI 模型与外部工具、数据源之间建立统一的通信桥梁。你可以把 MCP 理解为 AI 世界的"USB 接口"——它定义了一套标准化的方式，让 AI 助手能够安全、高效地与各种外部系统进行交互。

在 Claude Code 出现之前，每个 AI 工具想要访问外部资源（数据库、API、文件系统等），都需要单独编写集成代码。MCP 的出现改变了这一局面：只要服务器遵循 MCP 协议，任何支持 MCP 的客户端都可以无缝连接。

### 1.2 MCP 的架构：Client-Server 模型

MCP 采用经典的 **客户端-服务器（Client-Server）** 架构：

```
┌─────────────────┐       MCP 协议        ┌─────────────────┐
│                 │ ◄──────────────────► │                 │
│   MCP Client    │    JSON-RPC 2.0      │   MCP Server    │
│  (Claude Code)  │                      │  (工具提供方)    │
│                 │ ◄──────────────────► │                 │
└─────────────────┘                      └─────────────────┘
        │                                        │
        │                                        ├── 文件系统服务器
        │                                        ├── GitHub 服务器
        │                                        ├── 数据库服务器
        │                                        └── 自定义服务器...
```

- **MCP Client（客户端）**：Claude Code 就是一个 MCP 客户端，负责发起请求、调用工具
- **MCP Server（服务器）**：提供具体能力的服务方，如文件操作、API 调用、数据库查询等
- **通信协议**：基于 JSON-RPC 2.0，支持多种传输方式（stdio、SSE、HTTP）

### 1.3 MCP 提供的能力

MCP 服务器可以向客户端暴露三种核心能力：

| 能力类型 | 说明 | 示例 |
|---------|------|------|
| **Tools（工具）** | 可执行的操作，模型可以调用 | 查询数据库、创建 GitHub Issue、发送邮件 |
| **Resources（资源）** | 可读取的数据源 | 文件内容、数据库记录、API 响应 |
| **Prompts（提示模板）** | 预定义的提示词模板 | 代码审查模板、SQL 生成模板 |

在 Claude Code 中，**Tools** 是最常用的能力类型——Claude 会根据上下文自动判断何时调用哪个 MCP 工具。

### 1.4 Claude Code 作为 MCP Client

Claude Code 天然内置了 MCP 客户端能力。当你添加 MCP 服务器后，Claude Code 会：

1. 自动发现服务器提供的所有工具
2. 在对话上下文中展示可用工具列表
3. 根据用户请求智能选择合适的工具
4. 处理工具调用的权限确认流程

---

## 二、MCP 服务器安装与管理

### 2.1 通过命令行管理 MCP 服务器

Claude Code 提供了一组 `claude mcp` 子命令来管理 MCP 服务器：

#### 添加服务器

```bash
# 基本语法
claude mcp add <name> [options]

# 添加 stdio 类型的服务器（最常见）
claude mcp add my-server -s user -- npx -y @example/mcp-server

# 添加带环境变量的服务器
claude mcp add github-server -s user -e GITHUB_TOKEN=ghp_xxxx -- npx -y @modelcontextprotocol/server-github

# 添加 SSE 类型的服务器
claude mcp add remote-server --transport sse --url https://example.com/mcp/sse

# 添加 HTTP (Streamable HTTP) 类型的服务器
claude mcp add http-server --transport http --url https://example.com/mcp
```

#### 移除服务器

```bash
# 移除指定服务器
claude mcp remove my-server

# 从指定作用域移除
claude mcp remove my-server -s user
```

#### 查看已安装的服务器

```bash
# 列出所有已配置的 MCP 服务器
claude mcp list

# 查看特定服务器详情
claude mcp get my-server
```

### 2.2 服务器类型

MCP 支持三种传输（Transport）类型：

| 类型 | 说明 | 适用场景 |
|------|------|---------|
| **stdio** | 通过标准输入/输出通信 | 本地 Node.js/Python 服务器，最常用 |
| **sse** | Server-Sent Events | 远程服务器，需要持久连接 |
| **http** | Streamable HTTP | 远程服务器，标准 HTTP 请求 |

### 2.3 配置作用域（Scope）

添加服务器时可以指定作用域：

```bash
# 用户级别（全局生效）
claude mcp add my-server -s user -- command args

# 项目级别（仅当前项目生效，写入 .mcp.json）
claude mcp add my-server -s project -- command args
```

- **user 作用域**：配置保存在 `~/.claude/settings.json` 中，所有项目共享
- **project 作用域**：配置保存在项目根目录的 `.mcp.json` 中，随项目版本控制

---

## 三、`.mcp.json` 配置文件

### 3.1 文件位置和格式

`.mcp.json` 是项目级别的 MCP 配置文件，放在项目根目录下。它允许团队成员共享 MCP 服务器配置。

```
my-project/
├── .mcp.json          ← MCP 服务器配置
├── .claude/
│   └── settings.json  ← Claude Code 项目设置
├── src/
└── package.json
```

### 3.2 完整配置示例

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/home/user/projects"],
      "env": {}
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "ghp_your_token_here"
      }
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "postgresql://user:pass@localhost:5432/mydb"
      }
    }
  }
}
```

### 3.3 stdio 服务器配置详解

stdio 是最常用的服务器类型，通过子进程的标准输入/输出进行通信：

```json
{
  "mcpServers": {
    "my-stdio-server": {
      "command": "node",
      "args": ["path/to/server.js", "--flag", "value"],
      "env": {
        "API_KEY": "your-api-key",
        "DEBUG": "true"
      },
      "cwd": "/optional/working/directory"
    }
  }
}
```

配置字段说明：

| 字段 | 类型 | 说明 |
|------|------|------|
| `command` | string | 启动服务器的命令 |
| `args` | string[] | 命令行参数数组 |
| `env` | object | 环境变量键值对 |
| `cwd` | string | 工作目录（可选） |

### 3.4 SSE/HTTP 服务器配置

远程服务器使用 URL 方式配置：

```json
{
  "mcpServers": {
    "remote-sse": {
      "type": "sse",
      "url": "https://mcp.example.com/sse",
      "headers": {
        "Authorization": "Bearer your-token"
      }
    },
    "remote-http": {
      "type": "http",
      "url": "https://mcp.example.com/mcp",
      "headers": {
        "Authorization": "Bearer your-token"
      }
    }
  }
}
```

### 3.5 环境变量传递技巧

可以利用系统环境变量避免在配置文件中硬编码密钥：

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

> **提示**：`.mcp.json` 中可能包含敏感信息（如 API 密钥），建议将其添加到 `.gitignore` 中，或使用环境变量引用的方式。

---

## 四、常用 MCP 服务器

### 4.1 文件系统服务器

提供安全的文件系统读写能力：

```bash
claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem /path/to/allowed/dir
```

提供的工具：`read_file`、`write_file`、`list_directory`、`search_files` 等。

### 4.2 GitHub 服务器

与 GitHub API 集成，管理仓库、Issue、PR 等：

```bash
claude mcp add github -e GITHUB_TOKEN=ghp_xxx -- npx -y @modelcontextprotocol/server-github
```

提供的工具：`create_issue`、`list_pulls`、`create_pull_request`、`search_repos` 等。

### 4.3 数据库服务器

**PostgreSQL**：
```bash
claude mcp add postgres -e DATABASE_URL=postgresql://... -- npx -y @modelcontextprotocol/server-postgres
```

**SQLite**：
```bash
claude mcp add sqlite -- npx -y @modelcontextprotocol/server-sqlite /path/to/database.db
```

提供的工具：`query`、`execute`、`list_tables`、`describe_table` 等。

### 4.4 Puppeteer / 浏览器自动化

```bash
claude mcp add puppeteer -- npx -y @modelcontextprotocol/server-puppeteer
```

提供的工具：`navigate`、`screenshot`、`click`、`fill`、`evaluate` 等。适合网页测试、数据抓取等场景。

### 4.5 自定义服务器开发简介

你可以用 TypeScript 或 Python 快速开发自己的 MCP 服务器：

```typescript
// TypeScript 示例（使用 @modelcontextprotocol/sdk）
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const server = new McpServer({
  name: "my-custom-server",
  version: "1.0.0",
});

// 注册一个工具
server.tool(
  "hello",
  "向用户打招呼",
  { name: z.string().describe("用户名") },
  async ({ name }) => ({
    content: [{ type: "text", text: `你好，${name}！` }],
  })
);

// 启动服务器
const transport = new StdioServerTransport();
await server.connect(transport);
```

---

## 五、MCP OAuth 认证

### 5.1 OAuth 流程说明

部分 MCP 服务器（特别是远程服务器）需要 OAuth 认证。Claude Code 内置了对 OAuth 2.0 流程的支持：

1. Claude Code 检测到服务器需要认证
2. 自动打开浏览器引导用户完成授权
3. 获取并安全存储 access token
4. 后续请求自动携带 token

### 5.2 需要 OAuth 的服务器配置

```json
{
  "mcpServers": {
    "oauth-server": {
      "type": "http",
      "url": "https://mcp.example.com/mcp"
    }
  }
}
```

对于支持 OAuth 的远程服务器，通常不需要手动配置 token——Claude Code 会自动处理整个 OAuth 授权流程。

### 5.3 Token 管理

- Token 安全存储在本地，不会明文写入配置文件
- Token 过期后会自动刷新（如果服务器支持 refresh token）
- 可通过移除并重新添加服务器来重置认证状态

---

## 六、Hooks 系统概览

### 6.1 什么是 Hooks

**Hooks** 是 Claude Code 提供的一套生命周期钩子系统，允许你在特定事件发生时自动执行自定义的 Shell 命令。Hooks 以**确定性方式**运行用户定义的脚本——不依赖大模型的判断，而是在满足条件时必然触发。

### 6.2 Hooks 的设计目的

Hooks 系统解决了以下核心需求：

- **自动化流程**：工具调用前后自动执行格式化、检查等操作
- **安全防护**：拦截危险操作（如 `rm -rf /`）在执行前阻止
- **通知集成**：任务完成后发送通知到 Slack、邮件等
- **审计日志**：记录所有工具调用，满足合规性要求
- **自定义工作流**：将 Claude Code 深度集成到现有开发流程中

### 6.3 Hooks vs MCP 的区别

| 特性 | Hooks | MCP |
|------|-------|-----|
| **执行方式** | 确定性，条件匹配即执行 | 由模型决定是否调用 |
| **方向** | 被动触发（事件驱动） | 主动调用（模型驱动） |
| **用途** | 拦截、审计、自动化后处理 | 扩展模型的工具能力 |
| **配置位置** | settings.json | .mcp.json 或命令行 |
| **可见性** | 对模型透明 | 模型知道可用工具 |

简单来说：**MCP 是给 Claude 新能力，Hooks 是在 Claude 行动时做监听和干预。**

### 6.4 Hook 执行时机

```
用户提问
  │
  ▼
Claude 思考并决定调用工具
  │
  ├──► [PreToolUse Hook] ──► 可以拦截/修改
  │
  ▼
工具实际执行
  │
  ├──► [PostToolUse Hook] ──► 可以追加操作
  │
  ▼
Claude 继续思考或响应
  │
  ├──► [Stop Hook] ──► Claude 停止时触发
  │
  ▼
完成
```

---

## 七、Hook 事件列表

### 7.1 `PreToolUse` — 工具调用前

在 Claude 即将调用某个工具**之前**触发。这是最强大的 Hook，因为它可以**拦截并阻止**工具执行。

**传入数据（stdin JSON）**：
```json
{
  "session_id": "abc-123",
  "tool_name": "Bash",
  "tool_input": {
    "command": "npm install",
    "description": "Install dependencies"
  }
}
```

**使用场景**：
- 拦截危险的 Shell 命令
- 在文件写入前进行权限检查
- 记录即将执行的操作日志

### 7.2 `PostToolUse` — 工具调用后

在工具执行**完成之后**触发，可以获取工具的执行结果。

**传入数据（stdin JSON）**：
```json
{
  "session_id": "abc-123",
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "/path/to/file.ts",
    "old_string": "...",
    "new_string": "..."
  },
  "tool_result": "Successfully edited file"
}
```

**使用场景**：
- 文件编辑后自动运行格式化工具
- 代码修改后自动运行相关测试
- 记录操作结果日志

### 7.3 `Notification` — 通知事件

当 Claude Code 产生需要用户关注的通知时触发。

**使用场景**：
- 集成桌面通知系统
- 发送消息到 Slack/微信等

### 7.4 `Stop` — Claude 停止响应时

当 Claude 完成一轮对话（停止生成）时触发。

**传入数据（stdin JSON）**：
```json
{
  "session_id": "abc-123",
  "stop_reason": "end_turn",
  "message": "任务已完成..."
}
```

**使用场景**：
- 任务完成后发送通知
- 自动执行后续流程
- 生成任务完成报告

### 7.5 `SubagentStop` — 子代理停止时

当 Claude Code 的子代理（subagent）完成任务并停止时触发。与 `Stop` 类似，但专门针对子代理场景。

---

## 八、Hook 类型

### 8.1 command Hook — 执行 Shell 命令

目前 Hooks 支持的唯一类型是 **command**，即执行 Shell 命令。Hook 通过以下方式与 Claude Code 通信：

#### 输入（stdin）

Hook 脚本通过 **标准输入（stdin）** 接收 JSON 格式的事件数据：

```bash
#!/bin/bash
# 从 stdin 读取事件数据
input=$(cat)

# 用 jq 解析 JSON
tool_name=$(echo "$input" | jq -r '.tool_name')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

echo "工具: $tool_name, 命令: $command" >> /tmp/hook.log
```

#### 输出（stdout）

Hook 脚本可以通过 **标准输出（stdout）** 返回 JSON 格式的响应，用来控制后续行为：

```json
{
  "decision": "block",
  "reason": "该命令被安全策略禁止"
}
```

对于 `PreToolUse` Hook，可返回的决策包括：

| decision 值 | 说明 |
|-------------|------|
| `"approve"` | 自动批准，跳过用户确认 |
| `"block"` | 阻止执行，附带原因 |
| `"ask"` | 强制要求用户手动确认 |
| （无输出） | 使用默认行为 |

#### 退出码

| 退出码 | 含义 |
|--------|------|
| **0** | 成功，继续正常流程 |
| **2** | 阻止操作（仅 PreToolUse 有效） |
| **其他非零** | 表示错误，Claude Code 会显示 stderr 内容 |

---

## 九、Hook 配置格式

### 9.1 在 settings.json 中配置

Hooks 配置在 Claude Code 的 settings 文件中。可以配置在以下位置：

- **用户级别**：`~/.claude/settings.json`
- **项目级别**：`.claude/settings.json`

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/pre-bash-hook.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "prettier --write \"$EDIT_FILE_PATH\""
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "notify-send 'Claude Code' '任务已完成'"
          }
        ]
      }
    ]
  }
}
```

### 9.2 matcher 配置详解

`matcher` 字段用于匹配触发 Hook 的工具名称：

| matcher 值 | 匹配范围 |
|-----------|---------|
| `"Bash"` | 仅匹配 Bash 工具 |
| `"Edit"` | 仅匹配 Edit 工具 |
| `"Write"` | 仅匹配 Write 工具 |
| `"mcp__serverName__toolName"` | 匹配特定 MCP 服务器的特定工具 |
| `""`（空字符串） | 匹配所有工具 |

### 9.3 完整配置结构

```json
{
  "hooks": {
    "<EventName>": [
      {
        "matcher": "<tool_name_pattern>",
        "hooks": [
          {
            "type": "command",
            "command": "<shell_command>",
            "timeout": 10000
          }
        ]
      }
    ]
  }
}
```

字段说明：

| 字段 | 类型 | 说明 |
|------|------|------|
| `matcher` | string | 工具名匹配模式 |
| `hooks` | array | 要执行的 Hook 列表（可多个） |
| `hooks[].type` | string | Hook 类型，目前仅支持 `"command"` |
| `hooks[].command` | string | 要执行的 Shell 命令 |
| `hooks[].timeout` | number | 超时时间（毫秒），可选 |

---

## 十、实战示例

### 示例 1：自动格式化 — 每次 Edit 后运行 Prettier

每当 Claude 编辑文件后，自动运行代码格式化：

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "file_path=$(cat | jq -r '.tool_input.file_path') && npx prettier --write \"$file_path\" 2>/dev/null || true"
          }
        ]
      },
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "file_path=$(cat | jq -r '.tool_input.file_path') && npx prettier --write \"$file_path\" 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
```

### 示例 2：提交前检查 — Git Commit 前运行 Lint

拦截 git commit 命令，在提交前强制执行 lint 检查：

```bash
#!/bin/bash
# scripts/pre-commit-hook.sh

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# 仅拦截 git commit 命令
if [[ "$tool_name" == "Bash" && "$command" == *"git commit"* ]]; then
  # 运行 lint 检查
  lint_result=$(npm run lint 2>&1)
  lint_exit=$?

  if [ $lint_exit -ne 0 ]; then
    echo '{"decision": "block", "reason": "Lint 检查未通过，请先修复代码问题：'"$(echo "$lint_result" | tail -5 | jq -Rs .)"'"}'
    exit 0
  fi
fi

# 其他命令正常放行
exit 0
```

配置：
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash scripts/pre-commit-hook.sh"
          }
        ]
      }
    ]
  }
}
```

### 示例 3：通知系统 — Claude 完成任务后发送通知

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "notify-send 'Claude Code' '✅ 任务已完成' --urgency=normal"
          }
        ]
      }
    ]
  }
}
```

macOS 用户可以使用 `osascript`：

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"任务已完成\" with title \"Claude Code\"'"
          }
        ]
      }
    ]
  }
}
```

### 示例 4：自定义日志 — 记录所有工具调用

```bash
#!/bin/bash
# scripts/audit-log.sh

input=$(cat)
timestamp=$(date '+%Y-%m-%d %H:%M:%S')
session_id=$(echo "$input" | jq -r '.session_id')
tool_name=$(echo "$input" | jq -r '.tool_name')
tool_input=$(echo "$input" | jq -c '.tool_input')

echo "[$timestamp] session=$session_id tool=$tool_name input=$tool_input" >> ~/.claude/audit.log

exit 0
```

配置（对所有工具记录日志）：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash scripts/audit-log.sh"
          }
        ]
      }
    ]
  }
}
```

### 示例 5：安全审计 — 拦截危险命令

```bash
#!/bin/bash
# scripts/security-guard.sh

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [[ "$tool_name" != "Bash" ]]; then
  exit 0
fi

# 定义危险命令模式列表
dangerous_patterns=(
  "rm -rf /"
  "rm -rf ~"
  "mkfs\."
  "dd if=.* of=/dev/"
  "> /dev/sd"
  "chmod -R 777 /"
  "curl.*|.*sh"
  "wget.*|.*sh"
  ":(){ :|:& };:"
)

for pattern in "${dangerous_patterns[@]}"; do
  if echo "$command" | grep -qE "$pattern"; then
    echo "{\"decision\": \"block\", \"reason\": \"安全策略拦截：检测到危险命令模式 '$pattern'\"}"
    exit 0
  fi
done

# 安全命令正常放行
exit 0
```

配置：
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash scripts/security-guard.sh"
          }
        ]
      }
    ]
  }
}
```

---

## 十一、调试与排查

### 11.1 Hook 执行日志查看

Hook 执行的日志可以在 Claude Code 的输出中看到。如果 Hook 脚本出错，错误信息（stderr）会显示在界面上。

调试建议：

```bash
# 在 Hook 脚本中添加调试日志
#!/bin/bash
input=$(cat)
echo "$input" >> /tmp/hook-debug.log
echo "---" >> /tmp/hook-debug.log

# 正常处理逻辑...
```

### 11.2 常见错误处理

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| Hook 不触发 | matcher 不匹配 | 检查 matcher 是否与工具名完全匹配 |
| 权限拒绝 | 脚本无执行权限 | 运行 `chmod +x script.sh` |
| JSON 解析失败 | stdin 读取不完整 | 确保使用 `cat` 一次性读取所有输入 |
| Hook 超时 | 脚本执行时间过长 | 增加 timeout 配置或优化脚本 |
| 退出码错误 | 脚本异常退出 | 检查脚本逻辑，添加错误处理 |

### 11.3 MCP 服务器连接调试

当 MCP 服务器连接出现问题时：

```bash
# 1. 检查服务器是否正常启动
claude mcp list

# 2. 手动运行服务器命令，查看错误输出
npx -y @modelcontextprotocol/server-github 2>&1

# 3. 检查环境变量是否正确设置
echo $GITHUB_TOKEN

# 4. 查看 Claude Code 日志
# 日志通常位于 ~/.claude/logs/ 目录下
ls ~/.claude/logs/

# 5. 重新添加服务器
claude mcp remove my-server
claude mcp add my-server -- npx -y @example/server
```

**常见 MCP 连接问题排查清单**：

- [ ] 服务器命令路径是否正确
- [ ] 所需的环境变量（API Key 等）是否已设置
- [ ] Node.js/Python 版本是否满足要求
- [ ] 网络连接是否正常（远程服务器）
- [ ] 端口是否被占用（本地服务器）
- [ ] 防火墙是否放行了相关端口

---

> ⬅️ [上一章：子代理与Skills](Claude-code-06-agents.md) | [返回总览](Claude-code-guild.md) | ➡️ [下一章：实战工作流](Claude-code-08-workflows.md)
