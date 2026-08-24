# Claude Code 权限、安全与沙箱

> ⬅️ [上一章：记忆系统](Claude-code-04-memory.md) | [返回总览](Claude-code-guild.md) | ➡️ [下一章：子代理与Skills](Claude-code-06-agents.md)

---

## 1. 权限系统概览

### 1.1 为什么需要权限控制

Claude Code 是一个拥有强大执行能力的 AI 编程助手——它可以读写文件、执行 Shell 命令、访问网络、调用外部服务。这种能力在带来巨大生产力的同时，也意味着潜在的风险：

- **误操作风险**：AI 可能误删重要文件、覆盖未保存的修改
- **安全风险**：恶意提示注入可能诱导 AI 执行有害命令
- **隐私风险**：敏感信息（API 密钥、凭证文件）可能被意外读取或泄露
- **环境风险**：不受控的命令可能影响系统稳定性

因此，Claude Code 设计了一套 **多层次、细粒度** 的权限控制系统，确保用户始终掌握控制权。

### 1.2 权限模型设计理念

Claude Code 的权限模型遵循以下核心原则：

| 原则 | 说明 |
|------|------|
| **最小权限** | 默认情况下，所有写操作和命令执行都需要用户审批 |
| **显式授权** | 用户必须明确同意每一个潜在危险的操作 |
| **可配置** | 权限规则可以通过配置文件灵活定制 |
| **分层控制** | 用户级和项目级配置分离，互相补充 |
| **沙箱隔离** | 即使授权了操作，也在沙箱中执行以限制影响范围 |

权限系统的整体架构如下：

```
用户请求
  │
  ▼
┌─────────────────────┐
│   权限模式检查       │  ← default / plan / bypassPermissions
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│   权限规则匹配       │  ← allowedTools / disallowedTools
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│   交互式审批         │  ← Accept / Reject / Always Allow
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│   沙箱环境执行       │  ← 文件系统隔离 + 网络隔离
└─────────────────────┘
```

---

## 2. 权限模式详解

Claude Code 提供三种权限模式，通过 `--permission-mode` 标志设置：

```bash
# 启动时指定权限模式
claude --permission-mode default
claude --permission-mode plan
claude --permission-mode bypassPermissions
```

### 2.1 Default 模式（默认）

Default 模式是 Claude Code 的默认行为，采用 **逐一审批** 策略：

**只读操作（自动允许）：**
- 读取文件内容（`Read` 工具）
- 搜索文件（`Glob` 工具）
- 搜索内容（`Grep` 工具）
- 列出目录（`ls` 命令）

**需要审批的操作：**
- 写入或修改文件（`Edit`、`Write` 工具）
- 执行 Bash 命令
- 访问网络（`WebFetch`、`WebSearch`）
- 调用 MCP 工具
- 创建 Notebook 单元格

工作流程示例：

```
Claude: 我需要修改 src/app.ts 文件来修复这个 bug。
        [修改内容预览]

        ┌─────────────────────────────────┐
        │  Accept (y)                     │  ← 本次允许
        │  Reject (n)                     │  ← 本次拒绝
        │  Always Allow (a)               │  ← 本会话始终允许此工具
        │  Always Allow for this project  │  ← 此项目始终允许
        └─────────────────────────────────┘
```

当你选择 **Always Allow** 时，该权限会被记录到 settings.json 中，后续不再询问。

### 2.2 Plan 模式（只读探索）

Plan 模式将 Claude Code 限制为 **只读** 状态，非常适合以下场景：

- 代码审查和理解
- 项目架构分析
- Bug 定位和诊断
- 生成修改方案（但不执行）

```bash
claude --permission-mode plan
```

在 Plan 模式下：
- ✅ 可以读取任何文件
- ✅ 可以搜索代码
- ✅ 可以分析和解释代码
- ❌ 不能修改任何文件
- ❌ 不能执行写入命令
- ❌ 不能执行可能有副作用的 Bash 命令

```
你: 帮我分析一下这个项目的架构

Claude: [读取文件、搜索代码、分析依赖...]
        这个项目使用了 React + TypeScript 架构...
        建议的优化方案是...（但我不会直接修改文件）
```

### 2.3 bypassPermissions 模式（跳过所有权限）

> ⚠️ **危险模式** — 仅在受控的自动化环境中使用！

bypassPermissions 模式会跳过所有权限检查，Claude Code 可以无需确认地执行任何操作。

```bash
claude --permission-mode bypassPermissions --dangerously-skip-permissions
```

**注意事项：**
- 必须同时传递 `--dangerously-skip-permissions` 标志（双重确认机制）
- **绝对不要** 在个人开发环境中使用
- 仅适用于 CI/CD 流水线、自动化测试等受控场景
- 确保运行环境本身已有适当的安全隔离

典型 CI/CD 使用场景：

```yaml
# GitHub Actions 示例
- name: Claude Code Review
  run: |
    claude --permission-mode bypassPermissions \
           --dangerously-skip-permissions \
           -p "审查本次 PR 的代码变更并生成报告"
```

### 2.4 交互式权限审批流程

在 Default 模式下，当 Claude Code 需要执行受限操作时，会显示交互式审批提示：

```
Claude wants to execute: npm install lodash

  y  - Yes, allow this once          （本次允许）
  n  - No, deny this request          （本次拒绝）
  a  - Always allow this tool          （本会话始终允许此工具）
  p  - Always allow for this project   （此项目始终允许）
  ?  - Show more options               （更多选项）
```

选择 `a` 或 `p` 后，对应的权限规则会被写入 settings.json：

- `a`（会话级）→ 仅在当前会话有效
- `p`（项目级）→ 写入 `.claude/settings.json`，对该项目永久有效

---

## 3. 权限规则系统

### 3.1 工具级别的权限控制

Claude Code 的每个工具（Tool）都可以单独配置权限。主要工具列表：

| 工具名 | 功能 | 默认权限 |
|--------|------|----------|
| `Read` | 读取文件 | 自动允许 |
| `Glob` | 文件搜索 | 自动允许 |
| `Grep` | 内容搜索 | 自动允许 |
| `Edit` | 编辑文件 | 需要审批 |
| `Write` | 写入文件 | 需要审批 |
| `Bash` | 执行命令 | 需要审批 |
| `WebFetch` | 访问网页 | 需要审批 |
| `WebSearch` | 搜索网页 | 需要审批 |
| `NotebookEdit` | 编辑 Notebook | 需要审批 |
| `mcp__*` | MCP 工具 | 需要审批 |

### 3.2 allowedTools 和 disallowedTools

通过 `allowedTools` 和 `disallowedTools` 列表，可以精确控制哪些工具被允许或禁止：

```json
{
  "permissions": {
    "allowedTools": [
      "Edit",
      "Write",
      "Bash(npm test)",
      "Bash(git:*)",
      "WebFetch"
    ],
    "disallowedTools": [
      "Bash(rm -rf *)",
      "Bash(sudo:*)"
    ]
  }
}
```

**规则优先级：**

1. `disallowedTools` 优先于 `allowedTools`（黑名单优先）
2. 显式规则优先于默认规则
3. 项目级配置中的 `disallowedTools` 不能覆盖用户级的 `disallowedTools`

也可以通过命令行参数设置：

```bash
# 允许特定工具
claude --allowedTools "Edit" "Write" "Bash(npm test)"

# 禁止特定工具
claude --disallowedTools "Bash(rm:*)" "Bash(sudo:*)"
```

### 3.3 通配符匹配规则

权限规则支持通配符 `*` 进行模式匹配：

```
Bash(*)          → 匹配所有 Bash 命令
Bash(npm:*)      → 匹配所有以 npm 开头的命令（npm install, npm test 等）
Bash(git:*)      → 匹配所有以 git 开头的命令
mcp__*           → 匹配所有 MCP 工具
mcp__github__*   → 匹配 GitHub MCP 服务器的所有工具
```

匹配规则的细节：

```
规则                     匹配示例                    不匹配
───────────────────────────────────────────────────────────
Bash(npm test)          npm test                    npm install
Bash(npm:*)             npm test, npm install       node app.js
Bash(git:*)             git status, git commit      gitk
Bash(*)                 任何命令                     -
Edit                    所有文件编辑                  -
mcp__server__tool       特定 MCP 工具               其他工具
```

### 3.4 Bash 命令的特殊权限

Bash 命令的权限控制最为精细，因为 Shell 命令的风险程度差异很大：

```json
{
  "permissions": {
    "allowedTools": [
      "Bash(npm test)",
      "Bash(npm run:*)",
      "Bash(npx:*)",
      "Bash(git status)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Bash(ls:*)",
      "Bash(cat:*)",
      "Bash(head:*)",
      "Bash(tail:*)",
      "Bash(wc:*)",
      "Bash(find:*)",
      "Bash(grep:*)"
    ],
    "disallowedTools": [
      "Bash(rm -rf:*)",
      "Bash(sudo:*)",
      "Bash(chmod 777:*)",
      "Bash(curl|*)",
      "Bash(wget:*)"
    ]
  }
}
```

**实用的权限配置模板：**

```json
// 前端项目推荐配置
{
  "permissions": {
    "allowedTools": [
      "Edit",
      "Write",
      "Bash(npm:*)",
      "Bash(yarn:*)",
      "Bash(pnpm:*)",
      "Bash(npx:*)",
      "Bash(git:*)",
      "Bash(node:*)",
      "Bash(tsc:*)",
      "Bash(eslint:*)",
      "Bash(prettier:*)"
    ]
  }
}
```

```json
// Python 项目推荐配置
{
  "permissions": {
    "allowedTools": [
      "Edit",
      "Write",
      "Bash(python:*)",
      "Bash(pip:*)",
      "Bash(poetry:*)",
      "Bash(pytest:*)",
      "Bash(git:*)",
      "Bash(black:*)",
      "Bash(ruff:*)",
      "Bash(mypy:*)"
    ]
  }
}
```

### 3.5 网络访问权限控制

网络相关的权限需要特别关注：

```json
{
  "permissions": {
    "allowedTools": [
      "WebFetch",
      "WebSearch"
    ],
    "disallowedTools": [
      "Bash(curl:*)",
      "Bash(wget:*)",
      "Bash(ssh:*)",
      "Bash(scp:*)"
    ]
  }
}
```

---

## 4. settings.json 完整配置参考

### 4.1 配置文件位置

Claude Code 支持两级配置文件：

| 级别 | 路径 | 作用范围 | 优先级 |
|------|------|----------|--------|
| 用户级 | `~/.claude/settings.json` | 所有项目 | 较低 |
| 项目级 | `<项目根目录>/.claude/settings.json` | 当前项目 | 较高 |

**合并规则：**

- 项目级配置会与用户级配置合并
- 对于数组类型字段（如 `allowedTools`），两级配置会合并（取并集）
- 对于 `disallowedTools`，项目级 **不能** 移除用户级的禁止规则（安全考虑）
- 对于标量字段（如 `model`），项目级覆盖用户级

### 4.2 完整配置项说明

```jsonc
// ~/.claude/settings.json — 用户级完整配置示例
{
  // ========== 权限配置 ==========
  "permissions": {
    // 允许的工具列表（无需审批即可使用）
    "allowedTools": [
      "Edit",                    // 编辑文件
      "Write",                   // 写入文件
      "Bash(git:*)",             // 所有 git 命令
      "Bash(npm test)",          // npm test
      "WebFetch",                // 网页访问
      "mcp__github__*"           // GitHub MCP 所有工具
    ],

    // 禁止的工具列表（即使手动审批也无法使用）
    "disallowedTools": [
      "Bash(rm -rf /)",          // 危险的删除命令
      "Bash(sudo:*)",            // 所有 sudo 命令
      "Bash(chmod 777:*)"        // 危险的权限修改
    ]
  },

  // ========== 环境变量 ==========
  "env": {
    "NODE_ENV": "development",
    "CLAUDE_CODE_TIMEOUT": "300000"
  },

  // ========== 模型配置 ==========
  // 默认使用的主模型
  "model": "claude-sonnet-4-20250514",

  // 用于轻量级任务的小模型
  "smallModel": "claude-haiku-4-20250514",

  // ========== Hooks 配置 ==========
  "hooks": {
    // 会话开始时执行
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Bash command intercepted'"
          }
        ]
      }
    ],
    // 工具使用后执行
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'File written'"
          }
        ]
      }
    ],
    // 通知钩子
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "notify-send 'Claude Code' '$CLAUDE_NOTIFICATION'"
          }
        ]
      }
    ]
  },

  // ========== MCP 服务器配置 ==========
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/home/user/documents"
      ]
    }
  }
}
```

### 4.3 项目级配置示例

```jsonc
// <项目根目录>/.claude/settings.json — 项目级配置
{
  "permissions": {
    "allowedTools": [
      "Edit",
      "Write",
      "Bash(npm:*)",
      "Bash(git:*)",
      "Bash(node:*)",
      "Bash(npx:*)"
    ],
    "disallowedTools": [
      "Bash(npm publish:*)"
    ]
  },
  "env": {
    "NODE_ENV": "development",
    "DEBUG": "app:*"
  }
}
```

### 4.4 配置合并行为详解

当用户级和项目级配置同时存在时，合并规则如下：

```
用户级 allowedTools:     ["Edit", "Bash(git:*)"]
项目级 allowedTools:     ["Write", "Bash(npm:*)"]
最终 allowedTools:       ["Edit", "Bash(git:*)", "Write", "Bash(npm:*)"]  ← 取并集

用户级 disallowedTools:  ["Bash(sudo:*)"]
项目级 disallowedTools:  ["Bash(npm publish:*)"]
最终 disallowedTools:    ["Bash(sudo:*)", "Bash(npm publish:*)"]  ← 取并集

用户级 model:            "claude-sonnet-4-20250514"
项目级 model:            (未设置)
最终 model:              "claude-sonnet-4-20250514"  ← 使用用户级
```

**安全约束**：项目级配置无法移除用户级设置中的 `disallowedTools` 条目。这意味着如果你在用户级禁止了 `Bash(sudo:*)`，即使项目级配置中将它加入 `allowedTools`，它仍然会被禁止。

---

## 5. 沙箱系统

Claude Code 的沙箱系统为工具执行提供了操作系统级别的隔离，即使权限被授予，执行环境也被限制在安全边界内。

### 5.1 macOS 沙箱（基于 Seatbelt）

在 macOS 上，Claude Code 使用 Apple 的 **Seatbelt**（`sandbox-exec`）技术进行沙箱隔离：

```
┌─────────────────────────────────────┐
│           macOS Seatbelt            │
│  ┌───────────────────────────────┐  │
│  │  Claude Code 子进程           │  │
│  │                               │  │
│  │  ✅ 读取项目目录              │  │
│  │  ✅ 写入项目目录              │  │
│  │  ✅ 读写 /tmp 临时目录        │  │
│  │  ❌ 访问 ~/Documents 等      │  │
│  │  ❌ 访问系统关键目录          │  │
│  │  ❌ 修改系统配置              │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

Seatbelt 沙箱的关键限制：

- **文件系统**：只能访问项目目录、临时目录、以及必要的系统库
- **网络**：根据权限配置决定是否允许出站连接
- **进程**：限制可以创建的子进程类型
- **IPC**：限制进程间通信

### 5.2 Linux 沙箱（基于容器技术）

在 Linux 上，Claude Code 利用 **命名空间（namespaces）** 和 **cgroups** 等容器技术：

```
┌─────────────────────────────────────┐
│       Linux Namespace 沙箱          │
│  ┌───────────────────────────────┐  │
│  │  Mount namespace              │  │
│  │  ├── 项目目录 (bind mount)    │  │
│  │  ├── /tmp (tmpfs)             │  │
│  │  └── 必要的系统库             │  │
│  ├───────────────────────────────┤  │
│  │  Network namespace            │  │
│  │  └── 受控的网络访问           │  │
│  ├───────────────────────────────┤  │
│  │  PID namespace                │  │
│  │  └── 进程隔离                 │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

对于 Docker 环境，Claude Code 能检测到自身在容器中运行，并适应容器边界：

```bash
# 在 Docker 中运行 Claude Code
docker run -it \
  -v $(pwd):/workspace \
  -w /workspace \
  claude-code-image \
  claude --permission-mode bypassPermissions --dangerously-skip-permissions
```

### 5.3 文件系统隔离

沙箱的核心是文件系统隔离，确保 Claude Code 只能访问应该访问的文件：

**允许访问的路径：**
- 当前项目目录（`$PWD`）及其子目录
- 系统临时目录（`/tmp`、`$TMPDIR`）
- Claude Code 自身的配置和缓存目录
- 必要的系统共享库和运行时文件

**禁止访问的路径：**
- 用户主目录下的其他项目
- 系统配置目录（`/etc`、`/sys`）
- 其他用户的文件
- 敏感系统文件

### 5.4 网络隔离

沙箱中的网络访问也受到控制：

```
默认网络规则：
├── 允许：DNS 解析
├── 允许：HTTPS 出站连接（用于 API 调用）
├── 限制：HTTP 出站连接
├── 禁止：监听端口（入站连接）
└── 禁止：本地网络扫描
```

### 5.5 子进程继承沙箱

通过 Bash 命令创建的子进程会 **自动继承** 父进程的沙箱限制：

```bash
# Claude Code 执行的 Bash 命令
npm install          # → 在沙箱内执行，网络受限
node script.js       # → 在沙箱内执行，文件访问受限
git push             # → 在沙箱内执行，网络需要允许
```

这意味着即使一个 npm 包的 postinstall 脚本试图执行恶意操作，它也会被沙箱阻止。

---

## 6. 文件系统安全

### 6.1 只读 vs 读写工具

Claude Code 的工具按照文件操作权限分为两类：

```
只读工具（默认允许）：           读写工具（需要审批）：
├── Read   — 读取文件            ├── Edit    — 编辑文件
├── Glob   — 搜索文件名          ├── Write   — 写入新文件
├── Grep   — 搜索文件内容        ├── Bash    — 执行命令
└── Bash(ls/cat/head/...)        └── NotebookEdit — 编辑笔记本
```

这种分离确保 Claude Code 在分析代码时不会意外修改文件。

### 6.2 敏感文件保护

Claude Code 内置了对敏感文件的保护机制：

**默认保护的文件模式：**

```
.env                    # 环境变量（可能包含密钥）
.env.local              # 本地环境变量
.env.production         # 生产环境变量
*.pem                   # SSL/TLS 证书
*.key                   # 私钥文件
*credentials*           # 凭证文件
*secret*                # 密钥文件
id_rsa / id_ed25519     # SSH 私钥
.aws/credentials        # AWS 凭证
.npmrc                  # npm 配置（可能含 token）
.pypirc                 # PyPI 配置（可能含 token）
```

当 Claude Code 尝试读取或操作这些文件时，会发出额外的警告：

```
⚠️  Claude wants to read .env (sensitive file)
    This file may contain secrets or credentials.

    y - Allow   n - Deny
```

### 6.3 项目边界限制

Claude Code 默认将操作限制在项目目录内：

```
项目根目录: /home/user/myproject/
  ✅ /home/user/myproject/src/app.ts
  ✅ /home/user/myproject/package.json
  ✅ /home/user/myproject/.claude/settings.json
  ❌ /home/user/other-project/src/app.ts
  ❌ /home/user/.ssh/id_rsa
  ❌ /etc/passwd
```

如果确实需要访问项目外的文件，Claude Code 会请求显式授权。

### 6.4 符号链接处理

符号链接（Symlinks）可能被利用来绕过文件系统边界，因此 Claude Code 对其有特殊处理：

- **解析真实路径**：在进行路径检查前，先解析符号链接到其真实目标路径
- **边界检查**：如果符号链接指向项目目录外的文件，则视为越界访问
- **透明提示**：当操作涉及符号链接时，会显示真实路径让用户确认

```
Claude wants to read: ./config/secrets → /home/user/.secrets/prod.env
⚠️  This symlink points outside the project directory.

y - Allow   n - Deny
```

---

## 7. 网络安全

### 7.1 网络请求的权限控制

Claude Code 中的网络请求来源有多个渠道，每个渠道有独立的权限控制：

```
网络请求来源：
├── WebFetch 工具      → 通过 allowedTools 控制
├── WebSearch 工具     → 通过 allowedTools 控制
├── Bash 命令          → 通过 Bash 权限规则控制
│   ├── curl / wget
│   ├── npm install
│   ├── git push/pull
│   └── 其他网络命令
├── MCP 服务器         → 通过 MCP 配置控制
└── Claude API 通信    → 始终允许（核心功能）
```

### 7.2 WebFetch 和 WebSearch 的限制

WebFetch 和 WebSearch 工具有内置的安全限制：

**WebFetch 限制：**
- 自动将 HTTP 升级为 HTTPS
- 对返回内容进行大小限制
- 不执行 JavaScript（纯内容获取）
- 有 15 分钟的缓存机制
- 遵循重定向但会提示跨域重定向

**WebSearch 限制：**
- 结果经过安全过滤
- 不直接返回完整网页内容
- 支持域名过滤（`allowed_domains` / `blocked_domains`）

### 7.3 Bash 命令的网络访问

Bash 命令的网络访问需要格外注意，因为几乎任何程序都可能发起网络请求：

```json
{
  "permissions": {
    "allowedTools": [
      "Bash(npm install)",
      "Bash(git push:*)",
      "Bash(git pull:*)",
      "Bash(git fetch:*)"
    ],
    "disallowedTools": [
      "Bash(curl:*)",
      "Bash(wget:*)",
      "Bash(ssh:*)",
      "Bash(nc:*)",
      "Bash(ncat:*)",
      "Bash(telnet:*)"
    ]
  }
}
```

### 7.4 MCP 服务器的网络权限

MCP 服务器以独立进程运行，其网络权限取决于服务器实现。建议：

- 只使用可信来源的 MCP 服务器
- 通过环境变量传递凭证，而非硬编码
- 限制 MCP 服务器的工具范围

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  },
  "permissions": {
    "allowedTools": [
      "mcp__github__get_pull_request",
      "mcp__github__list_issues"
    ],
    "disallowedTools": [
      "mcp__github__delete_repository"
    ]
  }
}
```

---

## 8. 安全最佳实践

### 8.1 生产环境配置建议

```jsonc
// 推荐的用户级安全配置
// ~/.claude/settings.json
{
  "permissions": {
    "allowedTools": [
      // 只允许必要的工具
      "Edit",
      "Write"
    ],
    "disallowedTools": [
      // 全局禁止危险操作
      "Bash(rm -rf:*)",
      "Bash(sudo:*)",
      "Bash(chmod 777:*)",
      "Bash(chown:*)",
      "Bash(mkfs:*)",
      "Bash(dd:*)",
      "Bash(curl|bash)",
      "Bash(wget|bash)"
    ]
  }
}
```

### 8.2 CI/CD 环境安全

在 CI/CD 中使用 Claude Code 时，注意以下安全措施：

```yaml
# GitHub Actions 安全配置示例
name: Claude Code CI
on: [pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    # 最小权限原则
    permissions:
      contents: read
      pull-requests: write

    steps:
      - uses: actions/checkout@v4

      - name: Run Claude Code
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          claude --permission-mode bypassPermissions \
                 --dangerously-skip-permissions \
                 --output-format json \
                 -p "审查代码变更，输出 JSON 格式报告"
```

**CI/CD 安全检查清单：**

- [ ] 使用 GitHub Secrets 管理 API 密钥
- [ ] 设置最小的仓库权限
- [ ] 限制可以触发 Claude Code 的事件类型
- [ ] 使用只读模式进行代码审查
- [ ] 在隔离的容器中运行
- [ ] 设置执行超时时间
- [ ] 审计 Claude Code 的输出日志

### 8.3 团队共享安全策略

通过项目级 `.claude/settings.json` 建立团队统一的安全策略：

```jsonc
// .claude/settings.json — 提交到版本控制
{
  "permissions": {
    "allowedTools": [
      "Edit",
      "Write",
      "Bash(npm:*)",
      "Bash(git:*)",
      "Bash(npx:*)"
    ],
    "disallowedTools": [
      "Bash(npm publish:*)",
      "Bash(git push --force:*)",
      "Bash(git reset --hard:*)"
    ]
  },
  "env": {
    "NODE_ENV": "development"
  }
}
```

**团队协作建议：**

1. 将 `.claude/settings.json` 纳入版本控制
2. 在 PR 审查中关注 settings.json 的变更
3. 在团队 Wiki 中记录 Claude Code 安全策略
4. 定期同步更新安全配置

### 8.4 避免的危险操作

以下操作应当始终小心或禁止：

```
⛔ 高危操作（建议始终禁止）
├── rm -rf /                    # 删除根目录
├── sudo anything               # 提权操作
├── chmod 777                   # 开放所有权限
├── curl ... | bash             # 远程脚本执行
├── git push --force origin main # 强推主分支
├── DROP TABLE / DELETE FROM    # 数据库破坏性操作
└── npm publish                 # 意外发布包

⚠️ 中危操作（建议逐次审批）
├── git reset --hard            # 丢弃本地修改
├── rm -rf node_modules         # 删除依赖目录
├── docker system prune         # 清理 Docker
├── npm install <unknown-pkg>   # 安装未知包
└── 修改配置文件（nginx, etc）    # 服务配置变更

✅ 低危操作（可以配置自动允许）
├── git status / diff / log     # Git 只读操作
├── npm test                    # 运行测试
├── npm run lint                # 代码检查
├── ls / cat / head / tail      # 文件查看
└── node --version / npm -v     # 版本查询
```

### 8.5 敏感信息处理

处理敏感信息时的注意事项：

1. **永远不要在提示中包含密钥**
   ```bash
   # ❌ 错误
   claude -p "使用 API_KEY=sk-xxx123 来配置..."

   # ✅ 正确
   claude -p "使用环境变量 API_KEY 来配置..."
   ```

2. **使用环境变量传递敏感信息**
   ```json
   {
     "env": {
       "API_KEY": "${API_KEY}"
     }
   }
   ```

3. **确保 .env 文件在 .gitignore 中**
   ```gitignore
   .env
   .env.local
   .env.production
   ```

4. **不要让 Claude Code 提交敏感文件**
   ```json
   {
     "permissions": {
       "disallowedTools": [
         "Bash(git add .env:*)",
         "Bash(git add *.pem:*)",
         "Bash(git add *.key:*)"
       ]
     }
   }
   ```

### 8.6 定期审计建议

建立定期审计流程，确保 Claude Code 的使用安全：

**每周审计：**
- 检查 `~/.claude/settings.json` 中的 `allowedTools` 是否有不必要的权限
- 查看 Claude Code 的会话日志，确认没有异常操作
- 检查项目目录中是否有意外的文件变更

**每月审计：**
- 审查所有项目的 `.claude/settings.json` 配置
- 更新 MCP 服务器到最新版本
- 清理不再使用的 MCP 服务器配置
- 审查团队成员的 Claude Code 使用情况

**审计命令示例：**
```bash
# 查看当前的权限配置
cat ~/.claude/settings.json | jq '.permissions'

# 查看项目级权限配置
cat .claude/settings.json | jq '.permissions'

# 检查会话历史中的 Bash 命令
# Claude Code 会在每次会话结束后生成日志
ls ~/.claude/logs/
```

---

## 总结

Claude Code 的权限和安全系统是多层次的防护体系：

```
第1层：权限模式     → 控制整体行为（default/plan/bypass）
第2层：权限规则     → 控制工具级别的访问（allowedTools/disallowedTools）
第3层：交互审批     → 用户实时确认每个操作
第4层：沙箱隔离     → 操作系统级别的环境限制
第5层：内置保护     → 敏感文件检测、路径边界检查
```

**核心原则回顾：**

- 🔒 默认安全，最小权限
- 👁️ 透明可审计，用户始终掌控
- ⚙️ 灵活可配置，适应不同场景
- 🛡️ 多层防护，纵深防御

合理配置权限系统，可以在享受 Claude Code 强大能力的同时，确保代码和环境的安全。

---

> ⬅️ [上一章：记忆系统](Claude-code-04-memory.md) | [返回总览](Claude-code-guild.md) | ➡️ [下一章：子代理与Skills](Claude-code-06-agents.md)
