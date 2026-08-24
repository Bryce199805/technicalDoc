# Copilot-api 部署指南

https://github.com/ericc-ch/copilot-api

## 项目简介

Copilot API Proxy 是一个逆向工程代理工具，它能够将 GitHub Copilot 转换为一个“兼容 OpenAI 和 Anthropic 的服务”，从而使得你可以在其他平台（包括 Claude Code）上使用 Copilot 的底层模型能力。

## 主要特性

*   **API 兼容性**：暴露的端点匹配 OpenAI 的 Chat Completions 格式和 Anthropic 的 Messages API。
*   **用量监控**：提供基于 Web 的仪表板，用于跟踪 API 消耗和配额。
*   **速率控制**：支持限制请求频率和手动批准工作流的选项。
*   **账户灵活性**：支持 Individual（个人版）、Business（商业版）和 Enterprise（企业版）等不同的 GitHub Copilot 订阅。
*   **Token 管理**：支持在 CI/CD 环境中直接输入 GitHub Token。

## 部署方法

### 1. 使用 npx (最简单的方法)

无需安装，直接运行：

```bash
npx copilot-api@latest start
```

### 2. 使用 Docker 部署

适合需要在隔离环境中运行或部署到服务器上的场景：

```bash
docker run -p 4141:4141 -v $(pwd)/copilot-data:/root/.local/share/copilot-api copilot-api
```

### 3. 从源码运行 (需要 Bun ≥ 1.2.x)

如果你希望查看源码或进行二次开发：

```bash
bun install
bun run start
```

## 命令结构

该工具使用子命令进行操作：

*   `start`: 启动 API 服务器
*   `auth`: 仅执行 GitHub 身份验证
*   `check-usage`: 在终端显示配额信息
*   `debug`: 输出诊断信息

## 常用配置选项

在启动服务时，你可以附加一些参数来调整行为：

*   `--port`: 指定监听端口 (默认: 4141)
*   `--rate-limit <seconds>`: 强制在请求之间设置最小间隔时间
*   `--manual`: 在每个请求前需要手动批准
*   `--account-type`: 选择账户计划 (individual / business / enterprise)
*   `--claude-code`: 自动生成 Claude Code 配置

## ⚠️ 重要警告

文档强调：“过度自动或脚本化使用”存在触发滥用检测并可能导致 GitHub 账户被封禁的风险。在部署之前，请务必查阅并遵守 GitHub 的合理使用政策。