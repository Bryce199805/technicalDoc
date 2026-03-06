# Claude Code 记忆系统与 CLAUDE.md

> ⬅️ [上一章：交互模式](Claude-code-03-interactive.md) | [返回总览](Claude-code-guild.md) | ➡️ [下一章：权限与安全](Claude-code-05-permissions.md)

---

## 目录

- [1. 记忆系统概览](#1-记忆系统概览)
- [2. CLAUDE.md 文件层级](#2-claudemd-文件层级)
- [3. CLAUDE.md 编写指南](#3-claudemd-编写指南)
- [4. @引用语法](#4-引用语法)
- [5. .claude/rules/ 目录](#5-clauderules-目录)
- [6. 自动记忆机制](#6-自动记忆机制)
- [7. 记忆管理命令](#7-记忆管理命令)
- [8. 最佳实践](#8-最佳实践)

---

## 1. 记忆系统概览

### 1.1 为什么需要记忆系统

Claude Code 是一个基于大语言模型的编程助手，但每次启动新会话时，它对你的项目一无所知。记忆系统的核心目标就是解决这个问题——**让 Claude Code 在每次会话开始时，就已经"了解"你的项目、偏好和工作习惯**。

想象一下：每次打开 Claude Code，你都要重复告诉它"我们用 TypeScript"、"测试用 Jest"、"代码风格用单引号"……这显然很低效。记忆系统就是为了消除这种重复。

### 1.2 Claude Code 如何跨会话记忆信息

Claude Code 的记忆并非存储在模型本身中，而是通过**文件系统**来实现的。每次会话启动时，Claude Code 会自动读取一系列配置文件，将其作为系统上下文注入到对话中。这些文件就是 Claude Code 的"记忆"。

核心机制如下：

```
会话启动
  ├── 读取全局 CLAUDE.md（~/.claude/CLAUDE.md）
  ├── 读取项目根目录 CLAUDE.md
  ├── 读取 .claude/CLAUDE.md（团队共享）
  ├── 读取项目级用户 CLAUDE.md
  ├── 读取 .claude/rules/ 目录下的规则
  ├── 读取当前工作目录及子目录的 CLAUDE.md
  └── 合并所有内容 → 注入为系统上下文
```

### 1.3 记忆层级体系

Claude Code 的记忆采用**分层架构**，从全局到局部，层层细化：

| 层级 | 文件位置 | 作用范围 | 版本控制 |
|------|----------|----------|----------|
| 全局用户级 | `~/.claude/CLAUDE.md` | 所有项目 | 否 |
| 项目级用户 | `~/.claude/projects/<hash>/CLAUDE.md` | 特定项目（个人） | 否 |
| 项目根目录 | `<project>/CLAUDE.md` | 整个项目 | 是 |
| 团队共享 | `<project>/.claude/CLAUDE.md` | 整个项目（团队） | 是 |
| 子目录级 | `<project>/src/CLAUDE.md` | 特定目录 | 是 |
| 规则文件 | `<project>/.claude/rules/*.md` | 按条件匹配 | 是 |

这种分层设计的好处在于：

- **全局偏好**不需要在每个项目中重复
- **项目规范**可以被团队共享
- **个人偏好**不会污染团队配置
- **子目录规则**可以精确控制不同模块的行为

---

## 2. CLAUDE.md 文件层级

### 2.1 项目根目录 `CLAUDE.md`

这是最常用的记忆文件，放在项目根目录下，适用于整个项目。通常会纳入版本控制（Git），供团队所有成员共享。

```
my-project/
├── CLAUDE.md          ← 项目级记忆文件
├── package.json
├── src/
└── ...
```

**典型用途：**

- 项目整体介绍
- 技术栈说明
- 构建和测试命令
- 代码风格约定
- 项目目录结构

### 2.2 子目录 `CLAUDE.md`

当 Claude Code 在特定目录下工作时，它会自动加载该目录下的 `CLAUDE.md`。这允许你为不同的模块或子系统定义专属规则。

```
my-project/
├── CLAUDE.md               ← 全局项目规则
├── src/
│   ├── CLAUDE.md           ← src 目录专属规则
│   ├── components/
│   │   └── CLAUDE.md       ← 组件目录专属规则
│   └── utils/
│       └── CLAUDE.md       ← 工具函数专属规则
└── tests/
    └── CLAUDE.md           ← 测试目录专属规则
```

**示例 — `src/components/CLAUDE.md`：**

```markdown
# 组件开发规范

- 所有组件使用函数式组件 + Hooks
- 组件文件名使用 PascalCase
- 每个组件必须导出 Props 类型定义
- 样式使用 CSS Modules，文件名为 `ComponentName.module.css`
```

**加载规则：** 子目录的 `CLAUDE.md` 只在 Claude Code 访问该目录中的文件时才会加载。它不会覆盖项目根目录的规则，而是作为补充叠加生效。

### 2.3 用户级 `~/.claude/CLAUDE.md`

这是你的全局个人配置，对所有项目生效。适合存放个人的通用偏好。

```bash
# 文件位置
~/.claude/CLAUDE.md
```

**示例：**

```markdown
# 全局偏好

- 回复语言：中文
- 代码注释语言：英文
- 解释代码时请详细说明原理
- 使用 Git 提交时遵循 Conventional Commits 规范
- 生成代码时优先考虑可读性而非简洁性
```

> **注意：** 此文件不会被纳入任何项目的版本控制，属于纯个人配置。

### 2.4 项目级用户 `~/.claude/projects/<project>/CLAUDE.md`

这是特定项目的个人偏好，不纳入版本控制。适合存放你个人对某个项目的特殊需求，而这些需求不需要（或不适合）分享给团队。

```bash
# 文件位置（<project> 是项目路径的哈希值）
~/.claude/projects/<project-hash>/CLAUDE.md
```

**典型用途：**

- 个人的调试偏好
- 本地环境特有的配置
- 正在进行中的个人实验或任务上下文

**示例：**

```markdown
# 我的项目偏好

- 我负责 auth 模块，相关问题请优先查看 src/auth/
- 本地数据库端口改为 5433（非默认）
- 当前正在重构 UserService，请注意向后兼容性
```

### 2.5 `.claude/CLAUDE.md` — 团队共享配置

放在项目的 `.claude/` 目录下，专为团队协作设计。与项目根目录的 `CLAUDE.md` 类似，但组织上更清晰——`.claude/` 目录是 Claude Code 专属的配置空间。

```
my-project/
├── .claude/
│   ├── CLAUDE.md           ← 团队共享配置
│   └── rules/              ← 规则文件目录
├── CLAUDE.md               ← 项目级配置（也可并存）
└── ...
```

这两个文件可以共存，内容会合并加载。建议团队将通用规则放在 `.claude/CLAUDE.md` 中，将面向人类阅读的项目概述放在根目录 `CLAUDE.md` 中。

### 2.6 加载优先级和合并规则

Claude Code 启动时，所有层级的 CLAUDE.md 文件会被**合并**而非覆盖。合并遵循以下原则：

1. **全部加载：** 所有层级的文件内容都会被读取
2. **叠加生效：** 各层级的指令并行生效，不存在简单的"覆盖"
3. **就近优先：** 当指令冲突时，更具体（更局部）的规则优先级更高
4. **加载顺序：**
   - 全局用户配置（`~/.claude/CLAUDE.md`）
   - 项目级用户配置（`~/.claude/projects/<hash>/CLAUDE.md`）
   - 项目根目录配置（`CLAUDE.md`）
   - 团队共享配置（`.claude/CLAUDE.md`）
   - 子目录配置（按目录层级，从根到当前目录）
   - 规则文件（`.claude/rules/`）

**冲突示例：**

```
# 全局配置说：使用双引号
# 项目配置说：使用单引号
# 结果：在该项目中使用单引号（项目级更具体）
```

---

## 3. CLAUDE.md 编写指南

### 3.1 基本格式和语法

CLAUDE.md 使用标准的 **Markdown 格式**。Claude Code 能理解 Markdown 的所有常见语法，包括标题、列表、代码块、表格等。

**关键原则：**

- 使用简洁、明确的陈述句
- 使用祈使句直接给出指令（"使用 xxx"，而非"建议使用 xxx"）
- 善用列表和代码块提高可读性
- 避免过于冗长的描述——Claude Code 的上下文窗口有限

### 3.2 推荐的内容结构模板

一个完善的项目级 `CLAUDE.md` 通常包含以下部分：

```markdown
# 项目名称

## 项目概述
简要描述项目的目的和核心功能。

## 技术栈
- 语言 / 框架 / 运行时
- 数据库 / 缓存
- 构建工具 / 包管理器

## 常用命令
- 构建：`npm run build`
- 测试：`npm test`
- 格式化：`npm run format`
- 代码检查：`npm run lint`

## 代码风格
- 缩进、引号、分号等偏好
- 命名约定
- 导入排序规则

## 目录结构
项目关键目录的说明。

## 工作流偏好
- 分支策略
- 提交信息格式
- PR 流程
```

### 3.3 完整示例

下面是一个真实项目的 `CLAUDE.md` 示例：

```markdown
# TaskFlow - 任务管理平台

## 项目概述
TaskFlow 是一个基于 Web 的任务管理平台，支持看板视图、
时间追踪和团队协作。后端为 RESTful API，前端为 SPA。

## 技术栈
- 后端：Node.js + Express + TypeScript
- 前端：React 18 + TypeScript + Vite
- 数据库：PostgreSQL 15 + Prisma ORM
- 缓存：Redis
- 测试：Jest（后端）、Vitest（前端）
- CI/CD：GitHub Actions

## 常用命令

### 后端
- 启动开发服务器：`cd server && npm run dev`
- 运行测试：`cd server && npm test`
- 运行单个测试：`cd server && npm test -- --testPathPattern=<pattern>`
- 数据库迁移：`cd server && npx prisma migrate dev`
- 生成 Prisma 客户端：`cd server && npx prisma generate`

### 前端
- 启动开发服务器：`cd client && npm run dev`
- 构建生产版本：`cd client && npm run build`
- 运行测试：`cd client && npm run test`
- 类型检查：`cd client && npx tsc --noEmit`

## 代码风格

### 通用规则
- 使用 2 空格缩进
- 使用单引号
- 不使用分号
- 行尾无多余空格
- 文件末尾保留一个空行

### TypeScript 规范
- 优先使用 `interface` 而非 `type`（除非需要联合类型）
- 禁止使用 `any`，使用 `unknown` 代替
- 函数参数和返回值必须有类型标注
- 使用 `const` 声明默认不可变变量

### React 规范
- 使用函数式组件，禁止 class 组件
- 自定义 Hook 以 `use` 开头
- Props 类型定义在组件上方，命名为 `XxxProps`
- 事件处理函数命名为 `handleXxx`

### 命名约定
- 文件名：组件用 PascalCase，其他用 camelCase
- 变量/函数：camelCase
- 类型/接口：PascalCase
- 常量：UPPER_SNAKE_CASE
- 数据库表名：snake_case

## 目录结构
```
taskflow/
├── server/                 # 后端代码
│   ├── src/
│   │   ├── controllers/    # 路由控制器
│   │   ├── services/       # 业务逻辑
│   │   ├── models/         # 数据模型
│   │   ├── middleware/     # 中间件
│   │   ├── utils/          # 工具函数
│   │   └── types/          # 类型定义
│   ├── prisma/             # 数据库 schema 和迁移
│   └── tests/              # 测试文件
├── client/                 # 前端代码
│   ├── src/
│   │   ├── components/     # 可复用组件
│   │   ├── pages/          # 页面组件
│   │   ├── hooks/          # 自定义 Hooks
│   │   ├── stores/         # 状态管理（Zustand）
│   │   ├── services/       # API 调用
│   │   └── types/          # 类型定义
│   └── tests/              # 测试文件
└── docs/                   # 项目文档
```

## 工作流偏好
- Git 提交信息遵循 Conventional Commits：
  `<type>(<scope>): <description>`
- 类型：feat, fix, docs, style, refactor, test, chore
- 修改代码后运行相关测试确认无破坏
- 新增 API 端点时同步更新 `docs/api.md`
```

### 3.4 编写最佳实践

**简洁明确：**
```markdown
# 好 ✓
- 测试命令：`npm test`
- 使用单引号，不使用分号

# 不好 ✗
- 当你需要运行测试的时候，你可以在终端里输入 npm test 这个命令来执行所有的测试用例
- 在代码风格方面，我们倾向于使用单引号而不是双引号来包裹字符串
```

**使用 Markdown 结构化：**
- 用标题区分不同板块
- 用列表组织并列信息
- 用代码块标注命令和代码
- 用表格展示对比信息

**避免冲突：**
- 同一层级的不同文件不要给出相互矛盾的指令
- 团队统一在 `.claude/CLAUDE.md` 中定义共识性规则
- 个人偏好放在 `~/.claude/` 下，避免干扰团队配置

**控制篇幅：**
- 项目级 CLAUDE.md 建议控制在 200 行以内
- 过多的内容会消耗上下文窗口，降低 Claude Code 的效果
- 核心信息放前面，详细说明可以拆分到子目录的 CLAUDE.md

---

## 4. @引用语法

CLAUDE.md 支持 `@` 引用语法，允许你在记忆文件中动态引入外部内容，而不是手动复制粘贴。

### 4.1 `@file.txt` — 引用文件内容

将指定文件的内容引入到 CLAUDE.md 的上下文中。

```markdown
# 项目配置
请遵循以下 ESLint 配置：
@.eslintrc.json

# API 规范
请参考 API 文档：
@docs/api-spec.yaml
```

**注意：** 引用的文件路径是相对于 CLAUDE.md 所在目录的。

### 4.2 `@directory/` — 引用目录结构

引用目录时，Claude Code 会读取该目录的文件列表（非递归深层内容），帮助它理解项目结构。

```markdown
# 了解项目结构
@src/components/
@src/services/
```

### 4.3 `@url` — 引用网页

可以引用网页内容，Claude Code 会在加载 CLAUDE.md 时抓取该 URL 的内容。

```markdown
# 遵循团队编码规范
@https://wiki.example.com/coding-standards

# 参考设计文档
@https://docs.google.com/document/d/xxxxx
```

> **注意：** 网页引用依赖网络访问，在离线环境下可能无法加载。建议关键内容直接写入 CLAUDE.md，URL 引用作为补充。

### 4.4 使用场景和示例

**场景一：引用项目配置文件**

```markdown
# TypeScript 配置
请遵循此 tsconfig 配置进行类型检查：
@tsconfig.json
```

**场景二：引用规范文档**

```markdown
# 数据库 Schema
当前数据库结构参考：
@prisma/schema.prisma
```

**场景三：引用测试用例作为参考**

```markdown
# 测试风格
新测试请参考以下文件的编写风格：
@tests/example.test.ts
```

**场景四：结合目录和文件**

```markdown
# 项目核心模块
核心业务逻辑在以下目录中：
@src/core/

# 核心类型定义参考
@src/types/index.ts
```

---

## 5. `.claude/rules/` 目录

### 5.1 Rules 目录的作用

`.claude/rules/` 目录提供了一种更灵活的规则管理方式。与 CLAUDE.md 不同，rules 目录中的每个文件都是一条独立的规则，支持条件匹配——只在处理特定类型的文件时才生效。

```
.claude/
├── CLAUDE.md
└── rules/
    ├── general.md           # 通用规则（始终加载）
    ├── typescript.md        # TypeScript 相关规则
    ├── testing.md           # 测试相关规则
    └── api-design.md        # API 设计规则
```

### 5.2 规则文件格式

规则文件使用 Markdown 格式，文件名即规则名称。文件内容就是要传达给 Claude Code 的指令。

**示例 — `.claude/rules/typescript.md`：**

```markdown
# TypeScript 规范

## 类型安全
- 禁止使用 `any` 类型
- 使用 `unknown` 替代 `any`，然后通过类型守卫缩小范围
- 启用 `strict` 模式

## 错误处理
- 使用自定义错误类，继承自 `AppError`
- 异步函数统一使用 try/catch，不使用 .catch()
- 所有 API 响应错误必须经过 `ErrorHandler` 中间件

## 导入规则
- 使用路径别名 `@/` 代替相对路径
- 导入顺序：Node 内置模块 → 第三方库 → 内部模块 → 类型导入
- 类型导入使用 `import type { ... }`
```

### 5.3 与 CLAUDE.md 的区别

| 特性 | CLAUDE.md | .claude/rules/*.md |
|------|-----------|-------------------|
| 组织方式 | 单一文件，涵盖所有内容 | 多文件，按主题拆分 |
| 条件加载 | 不支持 | 支持 glob 模式匹配 |
| 适用场景 | 项目概述、常用命令 | 特定领域的详细规则 |
| 可维护性 | 内容多时难以维护 | 模块化，易于维护 |
| 团队协作 | 容易产生合并冲突 | 各文件独立，冲突少 |

### 5.4 条件规则（基于 glob 模式匹配）

rules 目录中的规则文件可以通过文件名中的 glob 模式来指定生效范围。当 Claude Code 正在处理的文件匹配该模式时，对应的规则才会被加载。

**命名格式：**

规则文件的文件名本身就是一个普通名称，条件匹配通过在文件开头使用 frontmatter 来实现：

```markdown
---
globs: ["*.tsx", "*.jsx"]
---

# React 组件规则

- 使用函数式组件
- Props 必须定义 TypeScript 接口
- 使用 memo() 包裹纯展示组件
```

```markdown
---
globs: ["*.test.ts", "*.spec.ts"]
---

# 测试规则

- 使用 describe/it 结构
- 每个 it 块只测试一个行为
- Mock 外部依赖，不 Mock 内部模块
```

**无 globs 的规则文件始终加载：**

```markdown
# 通用代码规则

- 函数不超过 50 行
- 文件不超过 300 行
- 嵌套深度不超过 3 层
```

### 5.5 示例规则文件

**`.claude/rules/git-commit.md`：**

```markdown
# Git 提交规则

- 提交信息使用英文
- 格式：`<type>(<scope>): <short description>`
- type 可选值：feat, fix, docs, style, refactor, perf, test, chore
- scope 用模块名，如 auth, api, ui
- description 不超过 72 字符
- 必要时添加 body 说明为什么做这个更改
```

**`.claude/rules/react-components.md`：**

```markdown
---
globs: ["src/components/**/*.tsx"]
---

# 组件开发规则

## 文件结构
每个组件一个目录：
```
ComponentName/
├── index.tsx           # 组件入口
├── ComponentName.tsx   # 组件实现
├── ComponentName.module.css  # 样式
├── ComponentName.test.tsx    # 测试
└── types.ts            # 类型定义
```

## 导出规范
- index.tsx 只做 re-export
- 组件使用命名导出，非默认导出
- 类型定义也需要导出
```

**`.claude/rules/database.md`：**

```markdown
---
globs: ["prisma/**", "src/models/**", "src/repositories/**"]
---

# 数据库规则

- 表名使用 snake_case 复数形式
- 主键统一命名为 `id`，类型为 UUID
- 时间字段必须包含 `created_at` 和 `updated_at`
- 使用软删除（`deleted_at`），不物理删除数据
- 所有查询使用 Prisma，禁止原生 SQL（除非有性能需求）
- 数据库迁移文件禁止手动修改
```

---

## 6. 自动记忆机制

### 6.1 Claude 如何自动学习和记忆

Claude Code 具备自动记忆的能力。在对话过程中，当你纠正它的行为、告知它某些偏好、或要求它"记住"某些事情时，它可以将这些信息自动写入记忆文件。

**自动记忆的触发场景：**

- 你纠正了 Claude 的错误假设（例如："不对，我们用的是 pnpm 而不是 npm"）
- 你明确要求记住某事（例如："记住，这个项目的测试要用 `--runInBand` 参数"）
- 你多次重复同一偏好，Claude 可能会主动提议记录

**自动记忆的工作流程：**

```
用户纠正/指示 → Claude 识别为可记忆信息
    → 询问用户是否保存（或自动保存）
    → 写入对应的记忆文件
    → 后续会话自动加载
```

### 6.2 `/memory` 命令手动编辑

你可以随时使用 `/memory` 命令打开记忆文件进行手动编辑：

```
> /memory
```

执行后，Claude Code 会打开当前项目的记忆文件（通常是 `~/.claude/projects/<hash>/CLAUDE.md`），你可以直接在编辑器中修改内容。

### 6.3 存储位置

自动记忆存储在用户目录下的 Claude 配置空间中：

```
~/.claude/
├── CLAUDE.md                           # 全局个人记忆
└── projects/
    ├── <project-hash-1>/
    │   └── CLAUDE.md                   # 项目 A 的个人记忆
    └── <project-hash-2>/
        └── CLAUDE.md                   # 项目 B 的个人记忆
```

**project hash** 是根据项目路径生成的，确保不同项目的记忆互不干扰。

你可以通过以下方式找到当前项目的记忆文件位置：

```bash
# 在 Claude Code 中直接询问
> 我的项目记忆文件在哪里？
```

### 6.4 记忆的内容类型

自动记忆通常会记录以下类型的信息：

| 类型 | 示例 |
|------|------|
| 工具偏好 | "使用 pnpm 而非 npm" |
| 代码风格 | "变量命名使用 camelCase" |
| 项目特定知识 | "数据库连接配置在 src/config/db.ts 中" |
| 工作流偏好 | "提交前先运行 lint" |
| 环境信息 | "本地 Node.js 版本为 20.x" |
| 常见错误修复 | "遇到 CORS 错误时检查 proxy 配置" |
| 架构决策 | "状态管理使用 Zustand 而非 Redux" |

### 6.5 记忆的自动更新和清理

记忆文件不会无限增长。Claude Code 在以下情况可能会更新记忆：

- **覆盖更新：** 当新信息与已有记忆冲突时，用新信息替换旧信息
- **手动清理：** 用户通过 `/memory` 命令手动编辑或删除
- **对话中要求：** 用户说"忘记关于 xxx 的记忆"，Claude 会从记忆文件中移除对应条目

> **建议：** 定期检查记忆文件，删除过时的信息，保持记忆的准确性和精简性。

---

## 7. 记忆管理命令

### 7.1 `/memory` — 打开记忆文件编辑

这是最直接的记忆管理方式：

```
> /memory
```

此命令会在你的默认编辑器中打开项目级用户记忆文件。你可以自由编辑内容，保存后即可在下次会话中生效。

### 7.2 `claude config` — 配置管理

`claude config` 命令用于管理 Claude Code 的配置选项（不仅限于记忆）：

```bash
# 查看所有配置
claude config list

# 设置配置项
claude config set <key> <value>

# 获取配置项
claude config get <key>
```

### 7.3 通过对话管理记忆

最自然的记忆管理方式是直接在对话中告诉 Claude：

**添加记忆：**

```
> 记住：这个项目使用 pnpm 作为包管理器
> 记住：API 路由前缀统一为 /api/v2
> 记住：部署前需要运行 npm run build:prod
```

**删除记忆：**

```
> 忘记关于包管理器的记忆
> 删除之前关于 API 前缀的记忆
> 把记忆中关于旧数据库配置的内容清除
```

**查看记忆：**

```
> 你现在记住了哪些关于这个项目的信息？
> 显示当前所有记忆内容
```

### 7.4 手动编辑记忆文件

你也可以直接用任何文本编辑器编辑记忆文件：

```bash
# 编辑全局记忆
vim ~/.claude/CLAUDE.md

# 编辑项目根目录记忆
vim ./CLAUDE.md

# 编辑团队共享记忆
vim ./.claude/CLAUDE.md

# 编辑规则文件
vim ./.claude/rules/typescript.md
```

手动编辑的好处：
- 可以进行批量修改
- 更精确地控制内容格式
- 适合初始化大量记忆内容
- 可以使用版本控制追踪变更

---

## 8. 最佳实践

### 8.1 项目级 vs 用户级记忆的选择

选择合适的记忆层级是高效使用 Claude Code 的关键：

| 场景 | 推荐层级 | 原因 |
|------|----------|------|
| 项目的技术栈和构建命令 | 项目级（`CLAUDE.md`） | 团队共享，所有人都需要 |
| 个人偏好的回复语言 | 全局用户级（`~/.claude/CLAUDE.md`） | 跨项目通用 |
| 个人的本地调试配置 | 项目级用户（`~/.claude/projects/`） | 项目相关但不需分享 |
| 特定目录的编码规范 | 子目录级（`src/CLAUDE.md`） | 仅该目录相关 |
| 按文件类型的规则 | Rules 目录（`.claude/rules/`） | 需要条件匹配 |

**决策流程：**

```
这条信息需要团队共享吗？
├── 是 → 放在项目级 CLAUDE.md 或 .claude/rules/
└── 否 → 这是跨项目通用的偏好吗？
    ├── 是 → 放在 ~/.claude/CLAUDE.md
    └── 否 → 放在 ~/.claude/projects/<hash>/CLAUDE.md
```

### 8.2 团队协作中的 CLAUDE.md 管理

**版本控制：**

```gitignore
# .gitignore 中不要忽略这些文件
# CLAUDE.md           ← 应该纳入版本控制
# .claude/CLAUDE.md   ← 应该纳入版本控制
# .claude/rules/      ← 应该纳入版本控制
```

**团队约定建议：**

1. **指定维护者：** 指定 1-2 人负责维护项目级 CLAUDE.md，避免频繁冲突
2. **PR 审查：** 对 CLAUDE.md 的更改纳入代码审查流程
3. **定期同步：** 团队定期讨论并更新 CLAUDE.md 中的规则
4. **文档化规则来源：** 在规则旁注释为什么要有这条规则

```markdown
# 代码风格

- 使用单引号（统一团队风格，2024-01 团队会议决定）
- 缩进 2 空格（ESLint 配置同步）
- 组件文件名用 PascalCase（与 React 社区惯例一致）
```

### 8.3 避免记忆冲突

记忆冲突是最常见的问题之一。以下是避免冲突的策略：

**层级分工明确：**

```
全局用户级     → 语言偏好、通用习惯
项目级         → 技术栈、命令、项目结构
子目录级       → 模块特有规则
Rules          → 文件类型特有规则
```

**不要重复定义：**

```markdown
# 不好 ✗ — 全局和项目级都定义了引号风格
# ~/.claude/CLAUDE.md: "使用双引号"
# ./CLAUDE.md: "使用单引号"

# 好 ✓ — 引号风格只在项目级定义
# ~/.claude/CLAUDE.md: （不提引号风格）
# ./CLAUDE.md: "使用单引号"
```

**使用明确的覆盖指令：**

```markdown
# 本项目覆盖全局设置
- 回复语言：英文（覆盖全局的中文偏好，因为团队为英语团队）
```

### 8.4 定期维护记忆文件

记忆文件需要像代码一样维护。建议建立以下维护习惯：

**每月检查清单：**

- [ ] 检查全局记忆是否有过时内容
- [ ] 检查项目记忆是否与当前技术栈一致
- [ ] 删除不再适用的规则
- [ ] 确认命令是否仍然正确（如版本升级后）
- [ ] 检查是否有重复或冲突的规则

**版本变更时：**

```markdown
# 当项目进行重大变更时，同步更新 CLAUDE.md
# 例如：
# - 从 JavaScript 迁移到 TypeScript
# - 更换包管理器（npm → pnpm）
# - 升级主要框架版本
# - 重构目录结构
```

**新成员入职时：**

确保 CLAUDE.md 中的内容足够新成员快速上手。可以让新成员在使用 Claude Code 时验证 CLAUDE.md 的有效性，并反馈需要补充的内容。

### 8.5 记忆文件大小建议

| 文件 | 建议行数 | 说明 |
|------|----------|------|
| 全局 `~/.claude/CLAUDE.md` | 10-30 行 | 只放最核心的个人偏好 |
| 项目级 `CLAUDE.md` | 50-200 行 | 覆盖项目主要方面即可 |
| 子目录 `CLAUDE.md` | 10-50 行 | 聚焦该目录的特殊规则 |
| Rules 文件（单个） | 10-50 行 | 每个文件聚焦一个主题 |

> **核心原则：** 记忆文件越精简，Claude Code 的表现越好。冗长的记忆会消耗上下文窗口，反而降低效果。只记录那些 Claude Code 无法从代码本身推断出来的信息。

### 8.6 常见误区

**误区一：把所有信息都写进 CLAUDE.md**

CLAUDE.md 不是项目文档，不需要事无巨细。它的目的是指导 Claude Code 的行为，而非给人类阅读。

**误区二：忽视记忆维护**

过时的记忆比没有记忆更糟糕——它会导致 Claude Code 按照错误的假设行事。

**误区三：全局配置过多**

全局配置应该尽量少，把大部分规则放在项目级。不同项目可能有完全不同的技术栈和风格。

**误区四：在记忆中存储敏感信息**

不要在 CLAUDE.md 中存储密码、API 密钥、Token 等敏感信息。特别是项目级的 CLAUDE.md 会被纳入版本控制。

---

## 总结

Claude Code 的记忆系统是提升开发效率的核心功能。合理利用 CLAUDE.md 的层级体系、rules 目录的条件规则、以及自动记忆机制，你可以让 Claude Code 在每次会话中都精准地理解你的项目和偏好。

**记住三个核心原则：**

1. **分层管理** — 全局偏好、项目规范、个人设置各归其位
2. **简洁明确** — 用最少的文字传达最关键的信息
3. **持续维护** — 像对待代码一样对待你的记忆文件

---

> ⬅️ [上一章：交互模式](Claude-code-03-interactive.md) | [返回总览](Claude-code-guild.md) | ➡️ [下一章：权限与安全](Claude-code-05-permissions.md)
