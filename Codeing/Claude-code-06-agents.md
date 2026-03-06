# Claude Code 子代理与 Skills

> ⬅️ [上一章：权限与安全](Claude-code-05-permissions.md) | [返回总览](Claude-code-guild.md) | ➡️ [下一章：MCP与Hooks](Claude-code-07-mcp-hooks.md)

---

## 目录

- [1. 子代理系统架构](#1-子代理系统架构)
- [2. 内置子代理类型](#2-内置子代理类型)
- [3. 使用子代理的场景](#3-使用子代理的场景)
- [4. 子代理参数详解](#4-子代理参数详解)
- [5. 子代理并行执行](#5-子代理并行执行)
- [6. Skills 系统](#6-skills-系统)
- [7. 自定义 Skills](#7-自定义-skills)
- [8. Agent Teams (并行协作)](#8-agent-teams-并行协作)
- [9. 最佳实践](#9-最佳实践)

---

## 1. 子代理系统架构

### 1.1 什么是子代理

子代理（Sub-agent）是 Claude Code 中的一个核心概念。当主代理（即你直接与之对话的 Claude）面临复杂任务时，它可以**生成独立的子代理**来处理特定的子任务。每个子代理都是一个完整的 Claude 实例，拥有自己的上下文窗口和工具集。

你可以将子代理理解为主代理的"助手"——主代理是项目经理，子代理是执行具体工作的工程师。

### 1.2 为什么需要子代理

子代理机制解决了几个关键问题：

| 问题 | 子代理如何解决 |
|------|---------------|
| **上下文窗口有限** | 子代理有独立的上下文，不占用主代理的窗口空间 |
| **复杂任务需要分解** | 将大任务拆分为多个独立子任务，各自由子代理执行 |
| **并行处理需求** | 多个子代理可以同时运行，大幅提升效率 |
| **隔离风险操作** | 子代理可以在 worktree 中隔离执行，避免影响主分支 |
| **专注性** | 子代理专注于单一任务，减少上下文切换导致的错误 |

### 1.3 主代理 vs 子代理的关系

```
┌──────────────────────────────────────────────┐
│                 主代理 (Main Agent)            │
│                                              │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐      │
│  │ 子代理A  │  │ 子代理B  │  │ 子代理C  │      │
│  │ (探索)   │  │ (规划)   │  │ (通用)   │      │
│  │ 只读工具  │  │ 只读工具  │  │ 全部工具  │      │
│  └─────────┘  └─────────┘  └─────────┘      │
│                                              │
│  主代理负责：                                  │
│  - 理解用户意图                                │
│  - 分配任务给子代理                             │
│  - 收集和整合子代理的结果                        │
│  - 与用户交互                                  │
└──────────────────────────────────────────────┘
```

**核心要点：**

- 主代理可以调用 `Agent` 工具来创建子代理
- 子代理执行完毕后，将结果返回给主代理
- 子代理**不能**再创建子代理（不支持递归嵌套）
- 子代理的工具集由其类型决定，通常是主代理工具集的子集

### 1.4 子代理的工具限制

子代理不是万能的。根据类型不同，它们能使用的工具有所差异：

```
主代理拥有的工具：
  Read, Write, Edit, Bash, Glob, Grep, Agent, WebFetch, WebSearch,
  NotebookEdit, EnterWorktree, Skill ...

子代理可能拥有的工具（因类型而异）：
  ✅ Read, Glob, Grep          — 所有子代理都有
  ⚠️ Write, Edit, Bash         — 仅通用子代理有
  ❌ Agent                     — 子代理不能再创建子代理
  ❌ EnterWorktree             — 子代理不能进入 worktree
```

> **注意**：子代理无法访问 `Agent` 工具，这意味着子代理不能嵌套创建更多子代理。这是一个有意为之的设计，防止无限递归和资源耗尽。

---

## 2. 内置子代理类型

Claude Code 提供了多种预定义的子代理类型，每种类型针对特定场景进行了优化。

### 2.1 general-purpose（通用子代理）

通用子代理是功能最完整的子代理类型，它几乎拥有主代理的所有工具（除了 `Agent` 本身）。

**特点：**
- 可以读写文件、执行命令、搜索代码
- 适合需要实际修改代码的任务
- 拥有独立的上下文窗口，不消耗主代理的上下文

**典型用途：**
- 实现一个具体的功能模块
- 修复一个 bug
- 重构某个文件或模块
- 编写测试用例

**调用示例（主代理内部逻辑）：**

```
Agent 调用参数：
  prompt: "在 src/utils/date.ts 中添加一个 formatRelativeTime 函数，
           支持中文输出（如'3分钟前'、'2小时前'、'昨天'）。
           请同时编写对应的单元测试。"
  subagent_type: "general-purpose"
  description: "实现相对时间格式化"
```

### 2.2 Explore（探索子代理）

探索子代理是**只读**的，它的任务是快速了解代码库的结构和内容，然后返回发现的信息。

**特点：**
- 只有只读工具：`Read`、`Glob`、`Grep`、`Bash`（只读命令）
- 不会修改任何文件
- 有三个深度级别，控制探索的彻底程度

**三个深度级别：**

| 级别 | 名称 | 说明 | 适用场景 |
|------|------|------|---------|
| 1 | `quick` | 快速浏览，只看表面结构 | 了解项目目录布局 |
| 2 | `medium` | 中等深度，阅读关键文件 | 理解某个模块的架构 |
| 3 | `very thorough` | 深入探索，全面阅读代码 | 深度理解实现细节 |

**调用示例：**

```
Agent 调用参数：
  prompt: "探索 src/auth/ 目录，了解当前的认证机制是如何实现的。
           特别关注 JWT token 的生成和验证流程。"
  subagent_type: "explore"
  description: "探索认证模块"
```

> **提示**：当你让 Claude Code "了解一下这个项目的结构" 或 "看看这个模块怎么工作的"，Claude 会倾向于使用探索子代理，因为这类任务不需要修改文件。

### 2.3 Plan（规划子代理）

规划子代理同样是只读的，但它的目标不是返回信息，而是**制定实现方案**。

**特点：**
- 只读工具，用于阅读现有代码
- 输出结构化的实现步骤计划
- 帮助主代理理解"应该怎么做"，而不是直接去做

**调用示例：**

```
Agent 调用参数：
  prompt: "分析当前项目的数据库层，设计一个从 MySQL 迁移到 PostgreSQL 的方案。
           列出需要修改的文件、步骤和潜在风险。"
  subagent_type: "plan"
  description: "规划数据库迁移"
```

**返回结果示例（子代理产出）：**

```markdown
## 数据库迁移方案

### 需要修改的文件
1. `src/config/database.ts` — 连接配置
2. `src/models/*.ts` — 16 个模型文件中的 MySQL 特有语法
3. `src/migrations/` — 所有迁移脚本需要重写
...

### 实施步骤
1. 安装 pg 驱动，移除 mysql2
2. 修改连接配置
3. 逐个模型修改 SQL 方言差异
...

### 风险点
- JSON 字段的处理方式不同
- 自增 ID 语法差异
...
```

### 2.4 claude-code-guide（指南子代理）

这是一个专门回答 Claude Code 使用问题的子代理。它内置了 Claude Code 的文档和使用知识。

**特点：**
- 专注于回答"如何使用 Claude Code"相关的问题
- 内置 Claude Code 的功能文档
- 不涉及具体的代码操作

**触发场景：**

```
用户: "Claude Code 怎么配置自动提交？"
用户: "什么是 CLAUDE.md？"
用户: "/help"
```

### 2.5 statusline-setup（状态栏子代理）

专门用于配置终端状态栏的子代理。

**特点：**
- 帮助用户配置 Claude Code 的状态栏显示
- 适配不同的终端和 shell 环境
- 自动检测终端类型并给出对应配置

---

## 3. 使用子代理的场景

### 3.1 代码库探索和分析

当你需要了解一个不熟悉的代码库时，子代理是最佳选择：

```
用户: "帮我了解一下这个项目的整体架构"

Claude 的处理方式：
  → 启动 Explore 子代理，深度 medium
  → 子代理浏览目录结构、阅读 README、查看关键配置文件
  → 子代理返回架构概览
  → 主代理整理并呈现给用户
```

### 3.2 并行处理独立任务

这是子代理最强大的能力之一——**并行执行**：

```
用户: "给这三个 API 端点都加上输入验证和错误处理"

Claude 的处理方式：
  → 同时启动 3 个通用子代理
  → 子代理 A: 处理 /api/users 端点
  → 子代理 B: 处理 /api/orders 端点
  → 子代理 C: 处理 /api/products 端点
  → 三个子代理并行工作
  → 主代理收集结果，确认一致性
```

### 3.3 隔离危险操作（Worktree 模式）

当子代理需要进行可能有风险的修改时，可以在 Git worktree 中隔离执行：

```
用户: "尝试将整个项目从 CommonJS 迁移到 ESM，但别影响当前代码"

Claude 的处理方式：
  → 启动通用子代理，设置 isolation: "worktree"
  → 子代理在独立的 worktree 中执行迁移
  → 迁移完成后在 worktree 中运行测试
  → 如果成功，主代理可以合并修改
  → 如果失败，worktree 可以安全丢弃
```

### 3.4 复杂任务分解

大型任务的分而治之策略：

```
用户: "实现一个完整的用户注册流程，包括前端表单、后端 API、数据库模型和邮件验证"

Claude 的处理方式：
  → 先启动 Plan 子代理，制定整体方案
  → 根据方案，并行启动多个通用子代理：
     - 子代理 A: 创建数据库模型和迁移
     - 子代理 B: 实现后端 API 端点
     - 子代理 C: 构建前端注册表单
     - 子代理 D: 实现邮件验证逻辑
  → 主代理检查各部分的集成，进行必要的调整
```

---

## 4. 子代理参数详解

当主代理调用 `Agent` 工具时，可以传递以下参数：

### 4.1 `prompt`（必需）

子代理要执行的任务描述。这是最重要的参数，决定了子代理会做什么。

```
prompt: "阅读 src/components/ 目录下的所有 React 组件，
         列出哪些组件使用了 class 语法而不是函数式语法，
         并给出重构建议。"
```

**编写好的 prompt 的要点：**
- 明确指定目标文件或目录
- 说清楚期望的输出格式
- 提供必要的上下文信息
- 设定完成标准

### 4.2 `description`（必需）

对子代理任务的简短描述，通常 3-5 个词。这个描述会显示在 Claude Code 的界面中，帮助用户了解当前正在执行什么。

```
description: "探索认证模块"
description: "修复分页 bug"
description: "编写单元测试"
```

### 4.3 `subagent_type`

指定子代理的类型，决定其工具集和行为模式。

```
subagent_type: "general-purpose"   // 通用，可读写
subagent_type: "explore"           // 探索，只读
subagent_type: "plan"              // 规划，只读
subagent_type: "claude-code-guide" // 使用指南
subagent_type: "statusline-setup"  // 状态栏配置
```

如果不指定，默认使用 `general-purpose`。

### 4.4 `run_in_background`

设为 `true` 时，子代理在后台运行。主代理可以继续执行其他操作，稍后再来收集结果。

```
run_in_background: true   // 后台运行
run_in_background: false  // 前台运行（默认），主代理等待完成
```

**后台运行的典型场景：**
- 同时启动多个独立任务
- 子代理任务耗时较长，主代理可以先做其他事
- 并行探索代码库的不同部分

### 4.5 `isolation: "worktree"`

让子代理在独立的 Git worktree 中运行。这意味着子代理的所有文件修改都在一个隔离的目录中进行，不会影响当前工作区。

```
isolation: "worktree"
```

**Worktree 隔离的工作流程：**

```
1. Claude 创建一个新的 git worktree
   → .claude/worktrees/<name>/
2. 子代理在这个 worktree 中工作
   → 所有读写操作都在隔离环境中
3. 子代理完成后
   → 修改保存在 worktree 的分支中
   → 主代理可以决定是否合并
```

### 4.6 `resume`

恢复一个之前中断或完成的子代理会话。当你想让子代理继续之前的工作时使用。

```
resume: "<session_id>"
```

---

## 5. 子代理并行执行

### 5.1 如何同时启动多个子代理

主代理可以在单次响应中调用多个 `Agent` 工具，从而并行启动多个子代理：

```
// 主代理同时发出三个 Agent 调用：

调用 1: Agent(
  prompt: "为 UserService 编写单元测试",
  description: "测试 UserService",
  run_in_background: true
)

调用 2: Agent(
  prompt: "为 OrderService 编写单元测试",
  description: "测试 OrderService",
  run_in_background: true
)

调用 3: Agent(
  prompt: "为 PaymentService 编写单元测试",
  description: "测试 PaymentService",
  run_in_background: true
)
```

### 5.2 前台 vs 后台执行

| 模式 | 行为 | 适用场景 |
|------|------|---------|
| **前台** | 主代理等待子代理完成才继续 | 后续步骤依赖子代理结果 |
| **后台** | 子代理在后台运行，主代理继续 | 多个独立任务并行执行 |

**前台执行示例：**

```
用户: "先分析一下现有代码，然后给我一个重构方案"

步骤 1 (前台): Explore 子代理分析代码 → 等待完成
步骤 2 (前台): Plan 子代理基于分析结果制定方案 → 等待完成
步骤 3: 主代理呈现方案给用户
```

**后台并行示例：**

```
用户: "修复这三个 bug"

同时启动 (后台):
  子代理 A: 修复 bug #1
  子代理 B: 修复 bug #2
  子代理 C: 修复 bug #3

主代理等待所有后台任务完成 → 汇总结果
```

### 5.3 结果收集和合并

当多个子代理并行执行完成后，主代理会：

1. **检查每个子代理的输出** — 确认任务是否成功完成
2. **检测冲突** — 如果多个子代理修改了同一文件，可能需要手动解决
3. **整合结果** — 将各子代理的工作整合成连贯的最终结果
4. **报告给用户** — 汇总所有子代理的工作成果

> **注意**：并行子代理修改同一个文件时可能产生冲突。尽量确保每个子代理负责不同的文件或模块。

### 5.4 实际示例：并行代码审查

```
用户: "审查最近的 PR，检查代码质量、安全性和性能"

Claude 的处理：

后台子代理 A (Explore):
  prompt: "审查 PR 中所有修改的文件，检查代码质量问题：
           命名规范、代码重复、函数复杂度等"
  description: "审查代码质量"

后台子代理 B (Explore):
  prompt: "审查 PR 中的代码，关注安全性问题：
           SQL 注入、XSS、敏感信息泄露等"
  description: "审查安全性"

后台子代理 C (Explore):
  prompt: "审查 PR 中的代码，关注性能问题：
           N+1 查询、不必要的循环、内存泄漏风险等"
  description: "审查性能"

→ 三个子代理同时工作
→ 主代理汇总三份审查报告
→ 呈现综合审查意见给用户
```

---

## 6. Skills 系统

### 6.1 Skills 是什么

Skills（技能）是 Claude Code 中预定义的**任务模板**。你可以将 Skill 理解为一个带有专门指令的"快捷方式"——它告诉 Claude 在执行特定类型的任务时应该遵循哪些步骤和规则。

Skills 的本质是一段 Markdown 格式的指令文本，在被触发时会被注入到 Claude 的上下文中，指导 Claude 完成特定任务。

### 6.2 Skills 与斜杠命令的关系

在 Claude Code 的交互界面中，你可以使用斜杠命令（`/command`）来触发 Skills：

```
/commit        → 触发 commit Skill，自动分析变更并创建提交
/review-pr     → 触发 PR 审查 Skill
/simplify      → 触发代码简化 Skill
/init          → 触发项目初始化 Skill
```

当用户输入斜杠命令时，Claude Code 会：
1. 查找匹配的 Skill
2. 调用 `Skill` 工具加载该 Skill 的指令
3. 按照 Skill 指令执行任务

> **要点**：并非所有 Skills 都通过斜杠命令触发。有些 Skills 可以通过用户意图自动识别并触发。

### 6.3 内置 Skills 详解

#### `/commit` — 代码提交

这是最常用的内置 Skill。它会：
- 运行 `git status` 和 `git diff` 查看变更
- 查看最近的 commit 历史以匹配提交风格
- 分析所有变更，草拟提交信息
- 暂存相关文件并创建提交
- 自动添加 `Co-Authored-By` 标注

```
用户: /commit
Claude: 分析变更... 创建提交:

  feat: add relative time formatting utility

  Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

#### `/review-pr` — PR 审查

审查 Pull Request 的 Skill：
- 获取 PR 的所有变更
- 从多个角度审查（正确性、安全性、性能、可维护性）
- 提供具体的改进建议
- 可以直接在 PR 上留下评论

#### `/simplify` — 代码简化

分析当前代码并建议简化方案：
- 识别过度复杂的逻辑
- 建议更简洁的实现方式
- 移除冗余代码

#### `/init` — 项目初始化

帮助在项目中初始化 Claude Code 配置：
- 创建 `CLAUDE.md` 文件
- 分析项目结构
- 设置合适的编码规范提示

---

## 7. 自定义 Skills

### 7.1 Skill 文件位置

自定义 Skills 存储在项目的 `.claude/skills/` 目录中：

```
项目根目录/
├── .claude/
│   ├── skills/
│   │   ├── deploy.md           # 部署 Skill
│   │   ├── create-component.md # 创建组件 Skill
│   │   └── database-migration.md
│   └── settings.json
├── src/
└── ...
```

### 7.2 Skill 文件格式

每个 Skill 文件由两部分组成：**YAML frontmatter** 和 **Markdown 正文**。

```markdown
---
name: create-component
description: 创建一个新的 React 组件，遵循项目约定
trigger:
  - /create-component
  - 创建组件
args:
  - name: component_name
    description: 组件名称
    required: true
  - name: type
    description: 组件类型 (page/layout/ui)
    default: ui
---

# 创建 React 组件

请按照以下步骤创建一个新的 React 组件：

## 步骤

1. 在 `src/components/{{type}}/` 目录下创建 `{{component_name}}/` 文件夹
2. 创建以下文件：
   - `index.tsx` — 组件主文件
   - `{{component_name}}.styles.ts` — 样式文件（使用 styled-components）
   - `{{component_name}}.test.tsx` — 测试文件
   - `{{component_name}}.stories.tsx` — Storybook 故事文件

## 组件模板

使用函数式组件 + TypeScript：
- 导出 Props 接口
- 使用 `React.FC<Props>` 类型
- 包含 `data-testid` 属性

## 项目规范

- 组件名使用 PascalCase
- 文件名与组件名一致
- 每个组件必须有对应的测试和 Story
```

### 7.3 Skill 触发条件配置

在 YAML frontmatter 的 `trigger` 字段中，可以配置多种触发方式：

```yaml
trigger:
  # 斜杠命令触发
  - /deploy
  - /deploy-staging

  # 自然语言关键词触发（Claude 会自动匹配意图）
  - 部署到生产环境
  - 发布新版本
```

### 7.4 参数传递

Skills 可以定义参数，用户在触发时传入：

```yaml
args:
  - name: target
    description: 部署目标环境
    required: true
    options:
      - staging
      - production
  - name: version
    description: 版本号
    required: false
    default: latest
```

**用户调用方式：**

```
/deploy staging v2.1.0
/deploy production
```

### 7.5 完整的自定义 Skill 示例

下面是一个用于数据库迁移的完整 Skill 示例：

```markdown
---
name: db-migrate
description: 创建并执行数据库迁移
trigger:
  - /db-migrate
  - 创建数据库迁移
  - 数据库变更
args:
  - name: migration_name
    description: 迁移名称（使用 snake_case）
    required: true
  - name: action
    description: 操作类型
    default: create
    options:
      - create
      - run
      - rollback
---

# 数据库迁移操作

## 创建迁移 (action: create)

1. 使用项目的 ORM 工具创建迁移文件：
   ```bash
   npx prisma migrate dev --name {{migration_name}} --create-only
   ```

2. 阅读生成的迁移文件，检查 SQL 语句是否正确

3. 确保迁移包含：
   - UP 迁移（正向变更）
   - DOWN 迁移（回滚逻辑）
   - 必要的数据迁移脚本

## 执行迁移 (action: run)

1. 先在测试数据库上执行：
   ```bash
   DATABASE_URL=$TEST_DB_URL npx prisma migrate deploy
   ```

2. 运行测试确保迁移不会破坏现有功能

3. 如果测试通过，提示用户确认是否在开发环境执行

## 回滚 (action: rollback)

1. 识别最近的迁移
2. 执行回滚操作
3. 验证数据完整性

## 注意事项

- 所有迁移必须是幂等的
- 大表变更需要考虑锁表问题
- 生产环境迁移需要额外审批
```

### 7.6 通过 MCP 服务器注册 Skills

除了文件方式，Skills 还可以通过 MCP (Model Context Protocol) 服务器动态注册。这允许外部工具和服务向 Claude Code 提供自定义能力：

```json
// .claude/settings.json
{
  "mcpServers": {
    "my-skills-server": {
      "command": "node",
      "args": ["./mcp-skills-server.js"],
      "skills": true
    }
  }
}
```

MCP 服务器可以动态提供 Skills，这意味着你可以：
- 根据项目状态动态生成 Skills
- 从团队共享的服务器加载统一的 Skills
- 集成第三方工具的专业能力

---

## 8. Agent Teams（并行协作）

### 8.1 多 Agent 协作模式

Agent Teams 是 Claude Code 中最强大的特性之一。它允许主代理像指挥团队一样，同时调度多个子代理协作完成复杂任务。

**协作模式示意：**

```
                    ┌─────────────┐
                    │   主代理     │
                    │  (指挥者)    │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
        ┌─────┴─────┐ ┌───┴────┐ ┌────┴─────┐
        │  Agent A   │ │ Agent B │ │  Agent C  │
        │ (worktree) │ │ (后台)  │ │ (worktree) │
        │  feature-1 │ │ explore │ │  feature-2 │
        └───────────┘ └────────┘ └──────────┘
```

### 8.2 Worktree 隔离并行开发

当多个子代理需要同时修改代码时，Worktree 隔离是必要的：

```
场景：同时开发两个独立功能

Agent A (worktree: feature-auth):
  → 在 .claude/worktrees/feature-auth/ 中工作
  → 创建分支 feature/auth
  → 实现用户认证功能
  → 所有修改隔离在自己的 worktree 中

Agent B (worktree: feature-search):
  → 在 .claude/worktrees/feature-search/ 中工作
  → 创建分支 feature/search
  → 实现搜索功能
  → 所有修改隔离在自己的 worktree 中

两个 Agent 不会互相干扰！
```

### 8.3 任务分配和结果合并

主代理在分配任务时需要考虑：

**任务分配原则：**
1. **独立性** — 尽量让每个子代理负责独立的模块，减少冲突
2. **清晰性** — 每个子代理的任务描述要具体明确
3. **粒度适当** — 不要把太大或太小的任务分给子代理

**结果合并流程：**

```
1. 所有子代理完成工作
2. 主代理检查每个 worktree 的变更
3. 依次合并各分支到主分支：
   git merge feature/auth
   git merge feature/search
4. 解决可能的合并冲突
5. 运行完整测试套件确认集成正确
```

### 8.4 实战示例：并行修复多个 Bug

假设你有三个独立的 bug 需要修复：

```
用户: "请修复以下三个 bug：
  1. 用户头像上传后不刷新
  2. 订单列表分页计算错误
  3. 搜索结果排序不正确"
```

**Claude 的执行策略：**

```
步骤 1: 分析三个 bug 的位置和独立性
  → 确认三个 bug 涉及不同模块，可以并行修复

步骤 2: 并行启动三个子代理（使用 worktree 隔离）

  Agent A (worktree: fix-avatar):
    prompt: "修复用户头像上传后不刷新的问题。
             可能的位置：src/components/Avatar/
             和 src/api/upload.ts。
             修复后编写测试验证。"
    isolation: "worktree"
    run_in_background: true

  Agent B (worktree: fix-pagination):
    prompt: "修复订单列表分页计算错误。
             查看 src/hooks/usePagination.ts
             和 src/pages/Orders/。
             确保边界情况处理正确。"
    isolation: "worktree"
    run_in_background: true

  Agent C (worktree: fix-search-sort):
    prompt: "修复搜索结果排序不正确的问题。
             检查 src/api/search.ts 中的
             排序逻辑和 SQL 查询。"
    isolation: "worktree"
    run_in_background: true

步骤 3: 收集结果
  → Agent A: ✅ 修复了缓存问题，添加了测试
  → Agent B: ✅ 修复了 off-by-one 错误，添加了测试
  → Agent C: ✅ 修复了 ORDER BY 方向，添加了测试

步骤 4: 依次合并三个修复分支
步骤 5: 运行完整测试套件
步骤 6: 汇报结果给用户
```

---

## 9. 最佳实践

### 9.1 何时使用子代理 vs 直接操作

**使用子代理的情况：**

| 场景 | 推荐方式 |
|------|---------|
| 任务可以并行化 | ✅ 多个后台子代理 |
| 需要探索大量代码 | ✅ Explore 子代理 |
| 需要隔离的实验性修改 | ✅ Worktree 子代理 |
| 任务复杂需要独立上下文 | ✅ 通用子代理 |
| 需要先规划再实施 | ✅ Plan 子代理 → 通用子代理 |

**直接操作更好的情况：**

| 场景 | 推荐方式 |
|------|---------|
| 修改单个文件的几行代码 | ❌ 不需要子代理 |
| 简单的搜索和替换 | ❌ 直接用 Edit 工具 |
| 运行一个命令 | ❌ 直接用 Bash 工具 |
| 快速查看一个文件 | ❌ 直接用 Read 工具 |

> **经验法则**：如果任务能在 2-3 个工具调用内完成，不需要子代理。如果任务涉及多文件、多步骤，或者需要并行执行，子代理就很有价值。

### 9.2 子代理的 Token 消耗考虑

子代理的 Token 消耗需要注意：

- **每个子代理都有独立的上下文窗口**，这意味着它们会消耗额外的 Token
- **探索子代理**通常消耗较少（主要是读取操作）
- **通用子代理**可能消耗较多（需要读取、思考、写入）
- **并行子代理**的总消耗 = 所有子代理消耗之和

**优化建议：**

```
✅ 好的做法：
  - 给子代理明确的范围限制（"只看 src/auth/ 目录"）
  - 使用合适的探索深度（不总是用 "very thorough"）
  - 对小任务直接操作，不启动子代理

❌ 不好的做法：
  - 对每个小改动都启动子代理
  - 给子代理模糊的指令（"看看代码有什么问题"）
  - 不必要的深度探索
```

### 9.3 提示词编写技巧

为子代理编写有效的 prompt 至关重要：

**好的 prompt 结构：**

```
1. 明确的目标
   "在 src/utils/validation.ts 中实现邮箱验证函数"

2. 必要的上下文
   "当前项目使用 zod 作为验证库，请保持一致"

3. 具体的要求
   "支持以下格式：标准邮箱、带+号的邮箱、国际域名"

4. 完成标准
   "确保通过所有现有测试，并添加新的测试用例覆盖边界情况"
```

**示例对比：**

```
❌ 差的 prompt:
  "修复登录的 bug"

✅ 好的 prompt:
  "修复 src/pages/Login/LoginForm.tsx 中的登录表单提交问题。
   用户报告：当密码包含特殊字符（如 & < >）时，提交失败。
   可能原因：表单数据在提交前未正确编码。
   请同时检查 src/api/auth.ts 中的请求构造逻辑。
   修复后添加对应的测试用例。"
```

### 9.4 错误处理

子代理可能会失败，主代理需要妥善处理：

**常见失败场景及应对：**

| 失败场景 | 应对策略 |
|---------|---------|
| 子代理超时 | 拆分为更小的子任务重试 |
| Worktree 合并冲突 | 主代理手动解决冲突 |
| 子代理修改了错误的文件 | 回滚变更，改进 prompt 后重试 |
| 多个子代理修改同一文件 | 串行执行而非并行，或重新划分任务边界 |
| 子代理上下文窗口耗尽 | 缩小任务范围，减少需要阅读的文件数量 |

**错误恢复示例：**

```
情况：子代理 A 和子代理 B 都修改了 config.ts，产生冲突

主代理的处理：
  1. 检测到冲突
  2. 读取两个子代理各自的修改意图
  3. 手动合并两个修改，确保逻辑一致
  4. 或者：回滚，重新安排任务，确保 config.ts 只被一个子代理修改
```

---

## 总结

Claude Code 的子代理和 Skills 系统为复杂任务提供了强大的处理能力：

- **子代理** 让 Claude 能够分而治之，并行处理多个任务
- **Skills** 提供了可复用的任务模板，标准化常见操作流程
- **Worktree 隔离** 确保并行操作的安全性
- **合理的任务分解** 是高效使用子代理的关键

掌握这些概念后，你将能够更高效地使用 Claude Code 处理大型、复杂的软件工程任务。

---

> ⬅️ [上一章：权限与安全](Claude-code-05-permissions.md) | [返回总览](Claude-code-guild.md) | ➡️ [下一章：MCP与Hooks](Claude-code-07-mcp-hooks.md)
