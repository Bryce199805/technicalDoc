# Claude Code 完整中文教程

> Claude Code 是 Anthropic 推出的官方命令行工具——一个运行在终端中的交互式 AI 软件工程助手。它能直接感知你的本地开发环境，读写文件、执行命令、搜索代码、浏览网页，帮助你完成从编码到部署的一切工作。

---

## 📖 教程导航

本教程体系由 **8 个专题模块** 组成，覆盖 Claude Code 的所有功能与最佳实践。你可以按顺序阅读，也可以根据需要跳转到感兴趣的章节。

| 模块 | 主题 | 说明 |
|------|------|------|
| [01 — 安装、启动与认证](Claude-code-01-install.md) | 🚀 快速上手 | 多平台安装、CLI 启动、账号认证、环境变量、云平台支持 |
| [02 — 核心工具详解](Claude-code-02-core-tools.md) | 🔧 工具百科 | Read / Edit / Write / Glob / Grep / Bash / WebFetch / WebSearch 完整用法 |
| [03 — 交互模式完全指南](Claude-code-03-interactive.md) | 💬 高效交互 | 斜杠命令、快捷键、会话管理、模型切换、Plan Mode、Checkpoint |
| [04 — 记忆系统与 CLAUDE.md](Claude-code-04-memory.md) | 🧠 记忆配置 | CLAUDE.md 编写指南、Rules 目录、@引用、自动记忆管理 |
| [05 — 权限、安全与沙箱](Claude-code-05-permissions.md) | 🔒 安全守护 | 权限模式、settings.json 配置、沙箱系统、安全最佳实践 |
| [06 — 子代理与 Skills](Claude-code-06-agents.md) | 🤖 智能协作 | Agent 系统架构、内置/自定义子代理、Skills 编写、Agent Teams |
| [07 — MCP 服务器与 Hooks](Claude-code-07-mcp-hooks.md) | 🔌 扩展能力 | MCP 协议、服务器配置、Hooks 生命周期、实战示例 |
| [08 — 实战工作流与最佳实践](Claude-code-08-workflows.md) | 🏗️ 实战指南 | Git 工作流、CI/CD 集成、IDE 集成、调试技巧、提示词工程 |

---

## ⚡ 快速入门（3 分钟上手）

### 第 1 步：安装

```bash
npm install -g @anthropic-ai/claude-code
```

> 详细的多平台安装方法请参考 [01 — 安装指南](Claude-code-01-install.md)

### 第 2 步：启动

在项目目录下运行：

```bash
claude
```

首次启动会引导你完成 Anthropic 账号认证（OAuth 浏览器登录）。

### 第 3 步：开始对话

进入交互模式后，直接用自然语言告诉 Claude 你想做什么：

```
> 帮我看一下 src/main.ts 的代码结构

> 找到所有使用了 deprecated API 的文件

> 运行测试并修复失败的用例

> 帮我写一个 Git commit message 并提交
```

### 第 4 步：创建项目记忆

在项目根目录创建 `CLAUDE.md`，告诉 Claude 你的项目偏好：

```markdown
# 项目规范
- 使用 TypeScript strict 模式
- 测试框架：Vitest
- 包管理器：pnpm
- 代码风格：遵循 .eslintrc.js
```

> 详细的 CLAUDE.md 编写指南请参考 [04 — 记忆系统](Claude-code-04-memory.md)

---

## 🗺️ 功能全景图

```
┌─────────────────────────────────────────────────────┐
│                   Claude Code CLI                    │
├─────────────────────────────────────────────────────┤
│  交互层    │  斜杠命令 · 快捷键 · Plan Mode · Todo  │
├─────────────────────────────────────────────────────┤
│  工具层    │  Read · Edit · Write · Bash · Glob     │
│           │  Grep · WebFetch · WebSearch · Agent    │
├─────────────────────────────────────────────────────┤
│  记忆层    │  CLAUDE.md · Rules · 自动记忆           │
├─────────────────────────────────────────────────────┤
│  安全层    │  权限系统 · 沙箱 · settings.json       │
├─────────────────────────────────────────────────────┤
│  扩展层    │  MCP 服务器 · Hooks · Skills · 子代理   │
├─────────────────────────────────────────────────────┤
│  集成层    │  Git · CI/CD · VS Code · JetBrains     │
└─────────────────────────────────────────────────────┘
```

---

## 💡 学习建议

- **新手用户**：从 [01 安装](Claude-code-01-install.md) 和 [02 核心工具](Claude-code-02-core-tools.md) 开始，掌握基础操作
- **日常使用**：重点阅读 [03 交互模式](Claude-code-03-interactive.md) 和 [04 记忆系统](Claude-code-04-memory.md)，提升使用效率
- **团队协作**：关注 [05 权限安全](Claude-code-05-permissions.md) 和 [08 工作流](Claude-code-08-workflows.md)，建立标准化流程
- **高级玩家**：深入 [06 子代理](Claude-code-06-agents.md) 和 [07 MCP/Hooks](Claude-code-07-mcp-hooks.md)，解锁全部潜力

---

## 📌 常用速查

| 操作 | 方式 |
|------|------|
| 启动 Claude | `claude` |
| 带初始提示启动 | `claude "你的问题"` |
| 继续上次会话 | `claude --continue` |
| 非交互模式 | `claude --print "你的问题"` |
| 快速模式 | 交互中输入 `/model` 切换模型 |
| 查看帮助 | `/help` 或 `claude --help` |
| 清空上下文 | `/clear` |
| 压缩上下文 | `/compact` |
| 进入规划模式 | `/plan` |
| 提交代码 | `/commit` |
| 退出 | `/exit` 或 `Ctrl+C` 两次 |

---

> **文档版本**：基于 Claude Code 2025–2026 版本编写
> **反馈与贡献**：欢迎通过 Issue 或 PR 提交改进建议
