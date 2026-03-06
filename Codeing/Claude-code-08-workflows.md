# Claude Code 实战工作流与最佳实践

> ⬅️ [上一章：MCP与Hooks](Claude-code-07-mcp-hooks.md) | [返回总览](Claude-code-guild.md)

---

本章是整个系列的**实战核心**，将覆盖日常开发中与 Claude Code 协同工作的完整工作流——从 Git 操作、CI/CD 集成、IDE 配合，到提示词工程和性能调优。掌握这些内容，你将能最大化利用 Claude Code 的生产力。

---

## 目录

- [1. Git 完整工作流](#1-git-完整工作流)
- [2. 非交互模式 (`--print`)](#2-非交互模式---print)
- [3. 管道与脚本集成](#3-管道与脚本集成)
- [4. CI/CD 集成](#4-cicd-集成)
- [5. IDE 集成](#5-ide-集成)
- [6. 代码开发工作流模式](#6-代码开发工作流模式)
- [7. `/doctor` 诊断](#7-doctor-诊断)
- [8. 常见问题与排查 (FAQ)](#8-常见问题与排查-faq)
- [9. 提示词工程技巧](#9-提示词工程技巧)
- [10. 性能优化建议](#10-性能优化建议)

---

## 1. Git 完整工作流

Claude Code 内置了强大的 Git 工作流支持。你可以用自然语言驱动几乎所有的 Git 操作，Claude 会自动选择安全的命令来执行。

### 1.1 自动提交：`/commit` 命令详解

`/commit` 是 Claude Code 最常用的斜杠命令之一，它会自动分析你的暂存区和工作区变更，生成高质量的提交信息。

```bash
# 在 Claude Code 交互式会话中直接输入：
> /commit
```

**Claude 会自动执行以下步骤：**

1. 运行 `git status` 查看所有未跟踪文件和变更
2. 运行 `git diff` 查看具体的代码改动
3. 运行 `git log` 查看最近的提交风格，保持一致性
4. 分析所有变更的性质（新功能、Bug 修复、重构等）
5. 生成简洁准确的提交信息
6. 将相关文件加入暂存区并执行提交

**提交信息规范：**
- Claude 会遵循项目已有的提交风格（如 Conventional Commits）
- 信息聚焦于"为什么"而非"改了什么"
- 自动添加 `Co-Authored-By: Claude` 标记
- 不会提交敏感文件（`.env`、凭证文件等）

```bash
# 提交信息示例
feat: add user authentication middleware

Implement JWT-based auth middleware to protect API routes.
Includes token validation, refresh logic, and role-based access.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

**注意事项：**
- 如果 pre-commit hook 失败，Claude 会修复问题后创建**新的提交**，而不是 amend
- Claude 优先使用 `git add <具体文件>` 而非 `git add -A`，避免误提交
- 如果没有任何变更，Claude 不会创建空提交

### 1.2 创建分支和切换分支

```bash
# 直接用自然语言
> 创建一个新分支 feature/user-auth，基于 main 分支

# Claude 会执行：
# git checkout -b feature/user-auth main

> 切换到 develop 分支
# git checkout develop

> 列出所有远程分支
# git branch -r
```

### 1.3 Pull Request 创建和审查

Claude Code 可以自动创建格式规范的 PR：

```bash
> 为当前分支创建一个 Pull Request

# Claude 会自动：
# 1. 分析当前分支与 base 分支的所有差异
# 2. 查看所有提交记录（不仅仅是最新的一个！）
# 3. 推送到远程仓库
# 4. 使用 gh pr create 创建 PR，包含摘要和测试计划
```

**生成的 PR 格式示例：**

```markdown
## Summary
- Add JWT authentication middleware for API routes
- Implement role-based access control (RBAC)
- Add comprehensive test coverage for auth flows

## Test plan
- [ ] Unit tests pass for token validation
- [ ] Integration tests for protected routes
- [ ] Manual testing with expired tokens
```

### 1.4 代码审查：`/review-pr` 命令

```bash
# 审查指定的 PR
> /review-pr 123

# 或者提供 PR URL
> /review-pr https://github.com/org/repo/pull/123
```

Claude 会深入分析 PR 的每一处变更，提供：
- 代码质量评估
- 潜在 Bug 识别
- 安全风险提示
- 性能影响分析
- 改进建议

### 1.5 Worktree 隔离开发

Worktree 允许你在不影响当前工作目录的情况下，在另一个目录中切出新分支进行开发：

```bash
# 在 Claude Code 中明确要求使用 worktree
> 请用 worktree 来处理这个 hotfix

# Claude 会：
# 1. 在 .claude/worktrees/ 下创建新的 worktree
# 2. 基于 HEAD 创建新分支
# 3. 将会话工作目录切换到新 worktree
# 4. 会话结束时提示你保留还是删除 worktree
```

**适用场景：**
- 紧急 hotfix，不想打断当前的功能开发
- 同时处理多个独立任务
- 需要在不同分支间快速切换并行工作

### 1.6 Git 冲突解决

```bash
> 帮我解决当前的 merge 冲突

# Claude 会：
# 1. 查看哪些文件有冲突
# 2. 读取冲突文件内容
# 3. 理解双方的改动意图
# 4. 智能合并，保留双方有效代码
# 5. 标记冲突为已解决
```

**提示：** 告诉 Claude 你更倾向于保留哪一方的改动，Claude 会据此做出判断：

```bash
> 解决冲突，优先保留 feature 分支的改动，但保留 main 的数据库配置
```

### 1.7 Rebase 和合并策略

```bash
# Rebase 当前分支到最新的 main
> 将当前分支 rebase 到 main 的最新提交上

# 交互式 rebase 压缩提交（Claude 不会使用 -i 标志）
> 将最近3个提交合并为一个
```

**注意：** Claude 不会使用 `git rebase -i`（交互模式），因为终端不支持交互输入。它会使用替代方式如 `git rebase --squash` 或 `git reset --soft` 来实现类似效果。

### 1.8 Claude 的 Git 安全原则

Claude Code 在执行 Git 操作时严格遵循以下安全原则：

| 原则 | 说明 |
|------|------|
| **不 force push** | 永远不会执行 `git push --force`，尤其是 main/master 分支 |
| **不 amend** | 除非用户明确要求，否则始终创建新提交 |
| **不跳过 hooks** | 不使用 `--no-verify`、`--no-gpg-sign` 等标志 |
| **不修改 git config** | 不会改动用户的 Git 全局或本地配置 |
| **不执行破坏性操作** | 不主动运行 `reset --hard`、`checkout .`、`clean -f`、`branch -D` |
| **精确暂存** | 优先使用 `git add <file>` 而非 `git add -A` |
| **敏感文件保护** | 不提交 `.env`、`credentials.json` 等敏感文件 |

> **关键理解：** 当 pre-commit hook 失败时，提交**并未发生**。此时如果使用 `--amend` 会修改**上一个**提交，可能导致代码丢失。Claude 理解这一点，会在修复后创建新提交。

---

## 2. 非交互模式 (`--print`)

非交互模式让 Claude Code 像传统命令行工具一样工作——接收输入、输出结果、退出。非常适合脚本自动化和管道集成。

### 2.1 什么是非交互模式

默认情况下，`claude` 命令启动一个交互式 REPL 会话。而 `--print`（简写 `-p`）标志会让 Claude 处理单个请求后直接退出，将结果输出到 stdout。

```bash
# 交互模式（默认）
claude

# 非交互模式
claude --print "你的问题或指令"
claude -p "你的问题或指令"
```

### 2.2 基本用法

```bash
# 简单问答
claude -p "解释 Python 的 GIL 是什么"

# 代码生成
claude -p "写一个 Python 函数，计算斐波那契数列的第 n 项"

# 分析当前项目
claude -p "这个项目使用了哪些技术栈？"
```

### 2.3 管道输入

Claude Code 可以接收 stdin 输入，与 `--print` 结合非常强大：

```bash
# 分析代码文件
cat src/auth.py | claude -p "找出这段代码中的安全漏洞"

# 分析日志
tail -100 /var/log/app.log | claude -p "分析这些日志，找出错误模式"

# 解释命令输出
docker ps | claude -p "解释每个容器的状态"

# 审查 diff
git diff HEAD~1 | claude -p "审查这些代码变更"
```

### 2.4 输出格式控制

`--output-format` 标志控制输出格式：

```bash
# 纯文本（默认）
claude -p "解释 async/await" --output-format text

# JSON 格式（适合程序解析）
claude -p "列出这个项目的依赖" --output-format json

# 流式 JSON（适合实时处理）
claude -p "分析代码质量" --output-format stream-json
```

**JSON 输出结构：**

```json
{
  "result": "Claude 的回复内容...",
  "cost_usd": 0.023,
  "duration_ms": 4521,
  "num_turns": 1
}
```

### 2.5 `--max-turns` 限制

限制 Claude 的对话轮次（tool use 循环次数），防止长时间运行：

```bash
# 最多执行 3 轮工具调用
claude -p "重构这个模块" --max-turns 3

# 单轮回答，不使用任何工具
claude -p "解释这段代码的作用" --max-turns 1
```

### 2.6 `--system-prompt` 自定义系统提示

覆盖默认的系统提示，控制 Claude 的行为风格：

```bash
# 以资深审查者的视角分析
claude -p "审查这段代码" --system-prompt "你是一位严格的高级代码审查者，关注安全性和性能"

# 以初学者友好的方式解释
claude -p "解释这段代码" --system-prompt "用简单易懂的语言解释，假设读者是编程初学者"
```

### 2.7 实际使用场景

```bash
# 场景1：快速代码解释
claude -p "解释 src/core/engine.rs 中 Process trait 的设计意图"

# 场景2：生成文档
claude -p "为 src/api/ 目录下所有公开接口生成 API 文档" > docs/api.md

# 场景3：数据转换
cat data.csv | claude -p "将这个 CSV 转换为 JSON 格式" > data.json

# 场景4：快速诊断
npm test 2>&1 | claude -p "分析测试失败的原因并给出修复建议"
```

---

## 3. 管道与脚本集成

Claude Code 设计为一个优秀的 Unix 公民，可以无缝融入你的命令行工作流。

### 3.1 Claude Code 作为 Unix 管道的一部分

```bash
# 查找大文件并分析
find . -size +1M -type f | claude -p "分析这些大文件，哪些可以安全删除？"

# 分析 Git 历史
git log --oneline -20 | claude -p "总结最近的开发活动"

# 处理 API 响应
curl -s https://api.example.com/status | claude -p "这个服务状态正常吗？"

# 链式管道
cat requirements.txt | claude -p "检查哪些包有已知的安全漏洞，输出 JSON" | jq '.vulnerabilities'
```

### 3.2 Shell 脚本中调用 Claude

```bash
#!/bin/bash
# review_changes.sh - 自动审查 Git 变更

set -euo pipefail

BRANCH=$(git branch --show-current)
BASE_BRANCH=${1:-main}

echo "正在审查 ${BRANCH} 相对于 ${BASE_BRANCH} 的变更..."

# 获取 diff 并让 Claude 审查
REVIEW=$(git diff "${BASE_BRANCH}...${BRANCH}" | claude -p \
  "请审查这些代码变更，关注以下方面：
   1. 潜在的 Bug
   2. 安全问题
   3. 性能问题
   4. 代码风格
   输出 Markdown 格式的审查报告" \
  --output-format text)

echo "${REVIEW}" > review_report.md
echo "审查报告已保存到 review_report.md"
```

### 3.3 多步骤自动化流程

```bash
#!/bin/bash
# auto_fix_lint.sh - 自动修复 lint 错误

set -euo pipefail

echo "步骤1: 运行 linter..."
LINT_OUTPUT=$(npx eslint src/ 2>&1) || true

if [ -z "${LINT_OUTPUT}" ]; then
  echo "没有 lint 错误！"
  exit 0
fi

echo "步骤2: 让 Claude 修复 lint 错误..."
echo "${LINT_OUTPUT}" | claude -p \
  "以下是 ESLint 的错误输出。请修复所有可自动修复的问题。
   只修改有错误的文件，不要重构其他代码。" \
  --max-turns 10

echo "步骤3: 重新运行 linter 验证..."
if npx eslint src/; then
  echo "所有 lint 错误已修复！"
else
  echo "仍有部分错误需要手动修复。"
  exit 1
fi
```

### 3.4 错误处理和重试机制

```bash
#!/bin/bash
# robust_claude.sh - 带错误处理的 Claude 调用

MAX_RETRIES=3
RETRY_DELAY=5

call_claude() {
  local prompt="$1"
  local attempt=1

  while [ ${attempt} -le ${MAX_RETRIES} ]; do
    echo "尝试第 ${attempt} 次..."

    if result=$(claude -p "${prompt}" --output-format json 2>&1); then
      echo "${result}"
      return 0
    fi

    echo "调用失败，${RETRY_DELAY} 秒后重试..."
    sleep ${RETRY_DELAY}
    attempt=$((attempt + 1))
  done

  echo "错误: ${MAX_RETRIES} 次尝试后仍然失败" >&2
  return 1
}

# 使用
call_claude "分析 src/ 目录的代码质量"
```

### 3.5 更多实用示例脚本

```bash
# 批量生成测试文件
for file in src/utils/*.ts; do
  claude -p "为 ${file} 生成单元测试" > "tests/$(basename "${file}" .ts).test.ts"
done

# 自动更新 CHANGELOG
git log --oneline v1.0.0..HEAD | claude -p \
  "根据这些提交记录，生成 CHANGELOG 条目，使用 Keep a Changelog 格式" \
  >> CHANGELOG.md

# 智能搜索和替换
claude -p "在整个项目中，将所有使用旧 API 'fetchData' 的地方迁移到新 API 'queryData'，
  注意参数格式也变了：旧的接收 string，新的接收 { query: string } 对象"
```

---

## 4. CI/CD 集成

Claude Code 可以集成到 CI/CD 流水线中，实现自动代码审查、自动修复和 PR 描述生成等功能。

### 4.1 GitHub Actions 中使用 Claude Code

**基本配置：**

```yaml
name: Claude Code Review
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install Claude Code
        run: npm install -g @anthropic-ai/claude-code

      - name: Run Code Review
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          git diff origin/main...HEAD | claude -p \
            "审查这些代码变更，提供简洁的反馈" \
            --output-format text > review.md

      - name: Post Review Comment
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const review = fs.readFileSync('review.md', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: review
            });
```

### 4.2 自动代码审查工作流

```yaml
name: Automated Code Review
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  claude-review:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install Claude Code
        run: npm install -g @anthropic-ai/claude-code

      - name: Analyze Changes
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          # 获取变更文件列表
          CHANGED_FILES=$(git diff --name-only origin/main...HEAD)

          # 让 Claude 深度审查
          claude -p "请审查以下文件的变更：
          ${CHANGED_FILES}

          重点关注：
          1. 逻辑错误和边界条件
          2. 安全漏洞（SQL注入、XSS等）
          3. 性能问题
          4. 缺失的错误处理
          5. 测试覆盖率

          使用以下格式输出：
          ## 审查摘要
          ## 严重问题
          ## 建议改进
          ## 优点" \
          --dangerously-skip-permissions \
          --output-format text > review_output.md

      - name: Comment on PR
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const body = fs.readFileSync('review_output.md', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## Claude Code Review\n\n${body}`
            });
```

### 4.3 自动修复 Lint 错误

```yaml
name: Auto Fix Lint
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  auto-fix:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.head_ref }}

      - name: Setup & Lint
        run: |
          npm ci
          npx eslint src/ 2>&1 > lint_errors.txt || true

      - name: Fix with Claude
        if: ${{ hashFiles('lint_errors.txt') != '' }}
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          cat lint_errors.txt | claude -p \
            "修复这些 lint 错误。只改动有问题的行，不要做额外的重构。" \
            --dangerously-skip-permissions \
            --max-turns 10

      - name: Commit Fixes
        run: |
          git config user.name "Claude Bot"
          git config user.email "claude-bot@example.com"
          git add -A
          git diff --cached --quiet || git commit -m "fix: auto-fix lint errors via Claude"
          git push
```

### 4.4 PR 描述自动生成

```yaml
name: Auto PR Description
on:
  pull_request:
    types: [opened]

jobs:
  describe:
    runs-on: ubuntu-latest
    permissions:
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Generate Description
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          COMMITS=$(git log --oneline origin/main...HEAD)
          DIFF_STAT=$(git diff --stat origin/main...HEAD)

          claude -p "根据以下提交记录和变更统计，生成 PR 描述：

          提交记录：
          ${COMMITS}

          变更统计：
          ${DIFF_STAT}

          使用以下格式：
          ## 变更概述
          ## 主要改动
          ## 测试说明" \
          --output-format text > pr_body.md

      - name: Update PR Body
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const body = fs.readFileSync('pr_body.md', 'utf8');
            github.rest.pulls.update({
              owner: context.repo.owner,
              repo: context.repo.repo,
              pull_number: context.issue.number,
              body: body
            });
```

### 4.5 安全注意事项

在 CI/CD 环境中使用 Claude Code 时，需要特别注意安全性：

```bash
# CI 环境中必须使用此标志（因为无法交互式确认权限）
claude -p "..." --dangerously-skip-permissions
```

**安全最佳实践：**

| 实践 | 说明 |
|------|------|
| API Key 使用 Secrets | 永远不要将 `ANTHROPIC_API_KEY` 硬编码在代码中 |
| 限制权限范围 | CI Job 只授予必要的最小权限 |
| 审查输出 | Claude 的自动修改应经过人工审查后再合并 |
| 限制 `--max-turns` | 在 CI 中设置合理的上限，避免失控 |
| 不自动合并 | Claude 的修改应该创建新的提交或 PR，而非直接合并到主分支 |
| 网络隔离 | 如有可能，限制 CI 环境中 Claude 可访问的网络资源 |

### 4.6 其他 CI 平台简介

**GitLab CI：**

```yaml
# .gitlab-ci.yml
claude-review:
  image: node:20
  stage: review
  before_script:
    - npm install -g @anthropic-ai/claude-code
  script:
    - git diff origin/main...HEAD | claude -p "审查代码变更" --output-format text > review.md
    - cat review.md
  variables:
    ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY}
  only:
    - merge_requests
```

**Jenkins（Jenkinsfile）：**

```groovy
pipeline {
    agent any
    environment {
        ANTHROPIC_API_KEY = credentials('anthropic-api-key')
    }
    stages {
        stage('Claude Review') {
            steps {
                sh '''
                    npm install -g @anthropic-ai/claude-code
                    git diff origin/main...HEAD | claude -p "审查代码" -output-format text
                '''
            }
        }
    }
}
```

---

## 5. IDE 集成

Claude Code 虽然是命令行工具，但可以与主流 IDE 和编辑器深度集成，提供更流畅的开发体验。

### 5.1 VS Code 集成

**安装 Claude Code VS Code 扩展：**

1. 打开 VS Code
2. 进入扩展市场（`Ctrl+Shift+X`）
3. 搜索 "Claude Code"
4. 安装官方扩展

**在编辑器内使用 Claude：**

```
# 安装后，可以通过以下方式启动：
# 1. 命令面板（Ctrl+Shift+P）→ "Claude Code: Open"
# 2. 侧边栏中的 Claude Code 图标
# 3. 快捷键（可自定义）
```

**核心功能：**
- 在编辑器侧边栏直接与 Claude 对话
- 选中代码后右键 → "Ask Claude" 来讨论特定代码段
- 内联代码建议和自动补全
- 终端面板中直接运行 Claude Code CLI

**终端集成：**

VS Code 的集成终端完全支持 Claude Code 的交互式模式：

```bash
# 在 VS Code 终端中启动
claude

# Claude 可以直接读取和编辑你在编辑器中打开的文件
> 修复当前打开的文件中第 42 行的 Bug
```

### 5.2 JetBrains IDE 集成

JetBrains 系列 IDE（IntelliJ IDEA, PyCharm, WebStorm 等）可以通过插件或终端集成 Claude Code。

**插件安装：**

1. 打开 Settings → Plugins → Marketplace
2. 搜索 "Claude Code" 或 "Claude"
3. 安装并重启 IDE

**配置方法：**

```
Settings → Tools → Claude Code
  ├── API Key: 配置 Anthropic API Key
  ├── Model: 选择默认模型
  └── Auto-permissions: 配置自动授权级别
```

**使用方式：**
- 右键代码 → "Analyze with Claude"
- 工具窗口中直接对话
- 在 Terminal 面板中使用 Claude Code CLI

### 5.3 Vim/Neovim 集成

Vim 和 Neovim 用户可以通过多种方式使用 Claude Code：

**方式一：内置终端**

```vim
" 在 Vim 中打开终端运行 Claude
:terminal claude

" Neovim 中
:term claude
```

**方式二：发送选中代码给 Claude**

```vim
" 在 .vimrc 或 init.vim 中添加
vnoremap <leader>cc :w !claude -p "解释这段代码"<CR>
vnoremap <leader>cf :w !claude -p "修复这段代码中的 Bug"<CR>
```

**方式三：使用 vim-claude 插件（社区维护）**

```vim
" 使用 vim-plug
Plug 'claude-vim/vim-claude'
```

### 5.4 终端复用器（tmux/screen）中使用

在 tmux 或 screen 中使用 Claude Code 可以保持会话持久性：

```bash
# 创建专用的 Claude tmux 窗格
tmux split-window -h 'claude'

# 在一个窗格中编码，另一个窗格中与 Claude 交互
# tmux 快捷键切换窗格：Ctrl+b → 方向键
```

**推荐的 tmux 布局：**

```
┌──────────────────┬─────────────────┐
│                  │                 │
│   编辑器/代码     │   Claude Code   │
│                  │    交互窗口      │
│                  │                 │
├──────────────────┴─────────────────┤
│         终端 / 测试输出             │
└────────────────────────────────────┘
```

---

## 6. 代码开发工作流模式

以下是经过验证的、与 Claude Code 协同工作的最佳工作流模式。

### 6.1 探索-规划-执行模式（推荐）

这是最推荐的工作流，特别适合复杂任务：

```
第一步：探索（Explore）
> 阅读 src/auth/ 目录下的代码，理解当前的认证机制

第二步：规划（Plan）
> 基于你对代码的理解，制定一个方案来添加 OAuth2 支持。
> 只列出计划，不要开始编码。

第三步：确认（Confirm）
> （你审查 Claude 的计划，提出修改意见）
> 计划看起来不错，但第3步应该用策略模式而不是 if-else

第四步：执行（Execute）
> 好的，按照修改后的计划开始实施
```

**为什么推荐这个模式？**
- 避免 Claude 一上来就"盲目"修改代码
- 让 Claude 先充分理解上下文
- 你可以在执行前审查和调整计划
- 减少返工的概率

### 6.2 TDD 工作流：测试驱动开发

```bash
# 第一步：让 Claude 先写测试
> 为用户注册功能编写单元测试，覆盖以下场景：
> - 正常注册
> - 邮箱已存在
> - 密码太弱
> - 缺少必填字段

# 第二步：运行测试（预期全部失败）
> 运行测试，确认它们都失败了

# 第三步：实现代码
> 现在实现注册功能，让所有测试通过

# 第四步：重构
> 测试都通过了。请审查实现代码，做必要的重构，确保测试仍然通过
```

### 6.3 Bug 修复工作流

```bash
# 第一步：描述问题
> 用户报告了一个 Bug：当购物车中商品数量为 0 时，
> 点击结算按钮会导致 500 错误。请找到问题根因。

# 第二步：Claude 分析代码，定位问题
# （Claude 会读取相关文件、搜索代码路径）

# 第三步：确认修复方案
> 你的分析正确。请修复这个问题，并添加回归测试。

# 第四步：验证
> 运行相关测试，确认修复有效
```

### 6.4 代码重构工作流

```bash
# 明确约束是关键
> 重构 src/services/payment.ts：
> - 将大函数拆分为小的、可测试的函数
> - 保持所有现有测试通过
> - 不改变公开 API 接口
> - 不修改其他文件
> - 每个函数不超过 20 行
```

### 6.5 新功能开发工作流

```bash
# 第一步：需求分析
> 我要在这个 Express.js 项目中添加文件上传功能。
> 分析现有代码结构，告诉我最合适的实现方式。

# 第二步：接口设计
> 设计上传 API 的接口，包括路由、请求格式和响应格式。
> 只给出设计，不要写代码。

# 第三步：逐步实现
> 先实现文件上传中间件
> 然后实现路由处理
> 最后添加测试

# 第四步：集成测试
> 编写端到端测试验证完整流程
```

### 6.6 代码迁移工作流

```bash
# 示例：从 JavaScript 迁移到 TypeScript
> 我想将 src/utils/ 目录从 JavaScript 迁移到 TypeScript。
> 请按以下步骤进行：
> 1. 先分析每个文件的类型使用情况
> 2. 创建必要的类型定义（.d.ts 或内联类型）
> 3. 逐个文件重命名并添加类型注解
> 4. 确保编译通过
> 5. 确保所有现有测试仍然通过
> 每完成一个文件就告诉我，等我确认后再继续下一个
```

---

## 7. `/doctor` 诊断

`/doctor` 命令用于诊断 Claude Code 的运行环境，帮助你快速定位问题。

### 7.1 诊断连接问题

```bash
> /doctor

# 输出示例：
# ✅ API 连接正常
# ✅ 认证有效
# ✅ 模型访问权限正常
# ⚠️ 网络延迟较高 (>500ms)
# ❌ MCP 服务器 "postgres" 无法连接
```

### 7.2 检查配置

`/doctor` 会检查所有配置层级：

```
检查项目：
├── API Key 是否有效
├── 网络连接状态
├── 当前使用的模型
├── 权限设置
├── 项目配置 (.claude/)
├── 全局配置 (~/.claude/)
├── MCP 服务器状态
└── 可用的工具列表
```

### 7.3 验证 MCP 服务器

如果你配置了 MCP 服务器，`/doctor` 会逐一检查每个服务器的连接状态：

```bash
# 诊断输出中的 MCP 部分
# MCP Servers:
#   ✅ filesystem - 运行中 (3 tools available)
#   ✅ postgres - 运行中 (5 tools available)
#   ❌ custom-api - 启动失败: "Connection refused on port 3001"
```

### 7.4 常见诊断结果解读

| 诊断结果 | 含义 | 解决方法 |
|----------|------|---------|
| ❌ API Key 无效 | Key 过期或错误 | 重新设置 `ANTHROPIC_API_KEY` |
| ❌ 网络不可达 | 无法连接 API 服务器 | 检查网络和代理设置 |
| ⚠️ 高延迟 | API 响应慢 | 检查网络状况或切换区域 |
| ❌ MCP 启动失败 | MCP 服务器配置错误 | 检查 MCP 配置文件和依赖 |
| ⚠️ 配置冲突 | 多层级配置有冲突 | 检查项目和全局配置的优先级 |
| ✅ 一切正常 | 所有检查通过 | 无需操作 |

---

## 8. 常见问题与排查 (FAQ)

### Q1: 上下文窗口满了怎么办？

**症状：** Claude 提示上下文即将用完，或者回复变得不连贯。

**解决方法：**

```bash
# 方法1：使用 /compact 压缩上下文
> /compact

# 方法2：带自定义指示的压缩
> /compact 保留关于数据库迁移的讨论内容

# 方法3：开始新会话并恢复
> /clear   # 清空当前会话

# 方法4：在新会话中通过提示词给出上下文
> 我正在进行用户认证模块的重构。之前已经完成了 JWT 中间件，
> 现在需要继续实现 refresh token 逻辑。请查看 src/auth/ 目录。
```

**预防措施：**
- 定期使用 `/compact` 而不是等到窗口满了
- 将大任务拆分为小任务，每个任务使用独立会话
- 避免让 Claude 读取大量不相关的文件

### Q2: Claude 修改了不该改的文件？

**症状：** Claude 在修复一个 Bug 时"顺手"重构了不相关的代码。

**解决方法：**

```bash
# 明确约束范围
> 只修改 src/cart/checkout.ts 文件的 calculateTotal 函数。
> 不要修改任何其他文件或函数。

# 使用 git 回滚不想要的更改
> 撤销对 src/utils/format.ts 的修改

# 在 CLAUDE.md 中设置全局规则
# CLAUDE.md:
# 重要：修改代码时只改动明确指定的文件，除非得到明确许可。
```

### Q3: 认证过期如何刷新？

```bash
# 方法1：重新运行认证流程
claude auth login

# 方法2：检查环境变量
echo $ANTHROPIC_API_KEY

# 方法3：使用 /doctor 诊断
> /doctor
```

### Q4: 响应速度慢的优化方法

```bash
# 1. 减少每次请求中的上下文量
> /compact

# 2. 使用更快的模型（如果可用）
> /model claude-sonnet-4-20250514

# 3. 限制工具调用次数
claude -p "..." --max-turns 3

# 4. 避免让 Claude 读取大文件
> 只看 src/main.ts 的第 50-100 行
```

### Q5: Token 用量过大如何控制？

**监控用量：**

```bash
# 查看单次请求的费用
claude -p "..." --output-format json | jq '.cost_usd'

# 查看会话累计用量
> /cost
```

**控制策略：**
- 使用 `--max-turns` 限制工具调用轮次
- 使用 `/compact` 定期压缩上下文
- 为 CI/CD 场景设置费用预警
- 将大任务拆分为小请求
- 使用 Sonnet 模型处理简单任务

### Q6: Claude 陷入循环怎么办？

**症状：** Claude 反复执行类似的操作却无法完成任务。

**解决方法：**

```bash
# 1. 按 Ctrl+C 中断当前操作
# 2. 给出更明确的指导
> 停下来。你刚才的方法行不通。
> 让我们换个思路：直接修改配置文件而不是生成代码。

# 3. 提供具体的解决方案
> 不要再尝试自动修复了。
> 在 config.json 中将 "retries" 从 3 改为 5 即可。
```

### Q7: 网络连接问题排查

```bash
# 检查 API 连通性
curl -s https://api.anthropic.com/v1/messages \
  -H "x-api-key: ${ANTHROPIC_API_KEY}" \
  -H "content-type: application/json" \
  -d '{"model":"claude-sonnet-4-20250514","max_tokens":10,"messages":[{"role":"user","content":"Hi"}]}'

# 如果使用代理
export HTTPS_PROXY=http://your-proxy:port
claude

# 检查 DNS 解析
nslookup api.anthropic.com
```

### Q8: 文件权限问题

```bash
# 症状：Claude 无法读取或写入文件
# 检查文件权限
ls -la src/config.ts

# 修复权限
chmod 644 src/config.ts

# 如果是目录权限问题
chmod 755 src/

# 注意：Claude 不会使用 sudo，也不应该需要
```

---

## 9. 提示词工程技巧

与 Claude Code 交互的质量很大程度上取决于你提示词的质量。以下是经验总结。

### 9.1 如何写出好的指令

**核心原则：像给一位新加入团队的资深工程师下达任务一样写指令。**

```bash
# ❌ 模糊的指令
> 修复 Bug

# ✅ 具体的指令
> src/api/users.ts 第 45 行的 getUserById 函数在传入 null 时会抛出
> TypeError。请添加空值检查，在 id 为空时返回 404 响应。
```

### 9.2 具体 > 模糊

```bash
# ❌ 模糊
> 让代码更好

# ✅ 具体
> 将 src/utils/parser.ts 中的 parseInput 函数重构为：
> 1. 使用 early return 替代嵌套 if
> 2. 将正则表达式提取为命名常量
> 3. 添加 JSDoc 注释
```

### 9.3 提供上下文

```bash
# ❌ 缺少上下文
> 为什么测试失败了？

# ✅ 提供充分上下文
> 运行 npm test -- --testPathPattern=auth 后，
> test/auth.test.ts 第 23 行的 "should reject expired tokens" 测试失败。
> 错误信息是 "Expected: 401, Received: 200"。
> 请查看 src/middleware/auth.ts 的 verifyToken 函数。
```

### 9.4 分步骤指导复杂任务

```bash
# ❌ 一次性说完所有需求
> 创建一个完整的用户管理系统，包括注册、登录、权限管理、
> 密码重置、邮箱验证、头像上传、个人资料编辑...

# ✅ 分步骤进行
> 第一步：创建用户注册的 API 接口和数据库模型
> （完成后再给出下一步）
```

### 9.5 约束输出

明确告诉 Claude 什么该做、什么不该做：

```bash
# 添加约束
> 修复这个 Bug：
> - 只修改 handleSubmit 函数
> - 不要重构其他代码
> - 不要添加新的依赖
> - 保持现有的代码风格
> - 修改后运行测试验证
```

### 9.6 让 Claude 先分析再行动

```bash
# ✅ 好的模式
> 在做任何修改之前，先分析 src/core/ 目录的代码架构，
> 然后告诉我你打算如何实现缓存功能。等我确认后再开始编码。

# ✅ 另一个好的模式
> 分析这段代码可能存在的问题，列出你的发现，但不要修改任何代码。
```

### 9.7 使用 @ 引用提供参考

在支持的环境中，可以使用 `@` 符号引用文件：

```bash
# 引用特定文件
> 参考 @src/types/user.ts 中的类型定义，为 @src/api/users.ts 添加类型注解

# 引用目录
> 分析 @src/services/ 目录的代码结构
```

### 9.8 避免的反模式

```bash
# ❌ 反模式1：过于宽泛的指令
> 优化整个项目

# ❌ 反模式2：不提供上下文就问"为什么"
> 为什么不工作？

# ❌ 反模式3：一次给太多不相关的任务
> 修复 Bug，然后添加新功能，顺便写文档，再部署到生产环境

# ❌ 反模式4：期望 Claude 记住之前的会话
> 继续昨天的工作  # Claude 不记得之前的会话！

# ❌ 反模式5：不审查就接受所有修改
# 始终审查 Claude 的代码变更，尤其是涉及安全、数据库和生产配置的部分
```

---

## 10. 性能优化建议

### 10.1 减少不必要的文件读取

```bash
# ❌ 低效：让 Claude 读取整个项目
> 读取所有代码文件然后告诉我架构

# ✅ 高效：指定目标文件
> 读取 src/index.ts 和 src/routes/ 目录，告诉我路由架构

# ✅ 更高效：先读取入口文件
> 先看 package.json 和 src/index.ts，了解项目结构后再深入
```

### 10.2 善用 `/compact` 管理上下文

```bash
# 在长时间会话中定期压缩
> /compact

# 在切换任务时压缩并保留关键信息
> /compact 保留关于 API 端点设计的讨论，丢弃其他内容

# 最佳实践：每完成一个子任务后压缩一次
```

**上下文管理策略：**

```
会话开始
  ├── 任务1：探索代码 → 完成 → /compact
  ├── 任务2：设计方案 → 完成 → /compact
  ├── 任务3：实现代码 → 完成 → /compact
  └── 任务4：测试验证 → 完成 → 提交
```

### 10.3 合理使用子代理

Claude Code 内部会使用子代理（Sub-agents）来处理复杂的搜索和分析任务。你可以通过以下方式优化：

```bash
# 减少搜索范围
> 只在 src/api/ 目录中搜索用户相关的路由  # 而非搜索整个项目

# 提供明确的文件路径
> 修改 src/services/auth.ts 的第 45 行  # 而非"找到认证相关的代码并修改"
```

### 10.4 选择合适的模型

不同任务适合不同模型：

```bash
# 复杂架构设计和深度分析 → 使用更强的模型
> /model claude-sonnet-4-20250514

# 简单代码生成和格式化 → 使用更快的模型
> /model claude-haiku-3-5
```

**模型选择指南：**

| 任务类型 | 推荐模型 | 原因 |
|----------|---------|------|
| 复杂重构 | Opus / Sonnet | 需要深度理解代码结构 |
| Bug 分析 | Sonnet | 平衡速度和分析能力 |
| 简单修改 | Haiku | 快速响应，节省 token |
| 代码审查 | Sonnet / Opus | 需要全面分析 |
| 文档生成 | Sonnet | 语言质量好，速度合理 |
| CI/CD 自动化 | Sonnet | 可靠且经济 |

### 10.5 综合优化清单

```
✅ 开始前指定好目标文件和范围
✅ 复杂任务使用"探索-规划-执行"模式
✅ 每完成一个子任务后 /compact
✅ 根据任务复杂度选择合适的模型
✅ 在 CLAUDE.md 中预设项目上下文和规则
✅ 使用 --max-turns 控制自动化任务的执行范围
✅ 定期查看 /cost 监控用量
✅ 将重复性操作提取到 Shell 脚本中
✅ 利用 MCP 让 Claude 直接查询数据库而非猜测
✅ 保持提示词简洁、具体、有约束
```

---

## 本章小结

本章介绍了 Claude Code 的核心实战工作流：

| 主题 | 关键要点 |
|------|---------|
| **Git 工作流** | `/commit` 自动提交、PR 创建审查、安全原则 |
| **非交互模式** | `--print` 单次执行、管道输入、输出格式控制 |
| **脚本集成** | Shell 脚本调用、管道组合、错误处理 |
| **CI/CD** | GitHub Actions 集成、自动审查、安全注意事项 |
| **IDE 集成** | VS Code、JetBrains、Vim、tmux |
| **开发模式** | 探索-规划-执行、TDD、Bug 修复、重构 |
| **诊断排查** | `/doctor` 命令、FAQ 常见问题 |
| **提示词技巧** | 具体、有上下文、有约束、先分析再行动 |
| **性能优化** | 减少文件读取、管理上下文、选择模型 |

**下一步建议：**
- 在你的日常项目中实践"探索-规划-执行"模式
- 尝试配置一个 GitHub Actions 自动审查工作流
- 创建项目级别的 `CLAUDE.md` 配置文件
- 建立适合团队的 Claude Code 使用规范

---

> ⬅️ [上一章：MCP与Hooks](Claude-code-07-mcp-hooks.md) | [返回总览](Claude-code-guild.md)
