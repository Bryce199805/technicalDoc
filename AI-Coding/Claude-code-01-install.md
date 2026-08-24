# Claude Code 安装、启动与认证

> ⬅️ [返回总览](Claude-code-guild.md) | ➡️ [下一章：核心工具详解](Claude-code-02-core-tools.md)

---

## 目录

- [1. 系统要求](#1-系统要求)
- [2. 安装方法](#2-安装方法)
- [3. 首次启动与认证](#3-首次启动与认证)
- [4. CLI 命令速查表](#4-cli-命令速查表)
- [5. 环境变量完整列表](#5-环境变量完整列表)
- [6. 云平台支持](#6-云平台支持)
- [7. 代理与网络配置](#7-代理与网络配置)
- [8. 常见安装问题排查](#8-常见安装问题排查)

---

## 1. 系统要求

在安装 Claude Code 之前，请确认你的系统满足以下最低要求：

| 要求项 | 最低版本 / 说明 |
|--------|----------------|
| **Node.js** | `>= 18.0.0`（推荐使用 LTS 20.x 或更高版本） |
| **npm** | 随 Node.js 一同安装即可（`>= 8.x`） |
| **操作系统** | macOS 12+、Ubuntu 20.04+ / Debian 11+ / 其他主流 Linux 发行版 |
| **Windows** | 必须通过 **WSL2**（Windows Subsystem for Linux）运行，不支持原生 Windows 命令行 |
| **磁盘空间** | 至少 500 MB 可用空间 |
| **网络** | 需要能访问 `api.anthropic.com`（直连或通过代理） |

### 检查 Node.js 版本

```bash
node --version
# 输出示例：v20.11.0  ✅
# 如果版本低于 18，请先升级 Node.js
```

### 快速安装 Node.js（如尚未安装）

**使用 nvm（推荐方式）：**

```bash
# 安装 nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# 重新加载 shell 配置
source ~/.bashrc   # 或 source ~/.zshrc

# 安装最新 LTS 版本
nvm install --lts
nvm use --lts
```

**macOS 使用 Homebrew：**

```bash
brew install node@20
```

**Ubuntu / Debian：**

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

---

## 2. 安装方法

Claude Code 提供多种安装途径，选择适合你的方式即可。

### 2.1 npm 全局安装（最通用）

这是官方推荐的主要安装方式，适用于所有支持 Node.js 的平台：

```bash
npm install -g @anthropic-ai/claude-code
```

> **提示：** 如果遇到权限错误（`EACCES`），请参考 [常见安装问题排查](#81-npm-全局安装权限问题) 部分。

### 2.2 curl 直接安装脚本

如果你不想手动管理 npm，可以使用官方提供的一键安装脚本：

```bash
curl -fsSL https://claude.ai/install.sh | sh
```

该脚本会自动检测系统环境、安装依赖并配置 PATH。

### 2.3 Homebrew 安装（macOS）

macOS 用户可以通过 Homebrew 来安装和管理 Claude Code：

```bash
brew install claude-code
```

后续升级：

```bash
brew upgrade claude-code
```

### 2.4 WinGet 安装（Windows）

Windows 用户可以通过 WinGet 在 WSL2 环境中安装：

```powershell
# 在 PowerShell 中（会安装到 WSL 环境）
winget install Anthropic.ClaudeCode
```

> **注意：** 安装完成后，务必在 WSL2 终端中运行 `claude`，而非原生 Windows 命令提示符。

### 2.5 验证安装

安装完成后，运行以下命令确认 Claude Code 已正确安装：

```bash
claude --version
# 输出示例：claude-code v1.0.16
```

```bash
which claude
# 输出示例：/usr/local/bin/claude 或 ~/.npm-global/bin/claude
```

### 2.6 更新 Claude Code

```bash
# npm 方式更新
npm update -g @anthropic-ai/claude-code

# 或 Homebrew 方式
brew upgrade claude-code
```

---

## 3. 首次启动与认证

### 3.1 启动 Claude Code

在终端中输入以下命令进入交互模式：

```bash
claude
```

首次运行时，Claude Code 会引导你完成认证流程。

### 3.2 OAuth 浏览器认证（推荐）

这是默认的认证方式，适用于拥有 Anthropic Console 账号的用户：

1. 运行 `claude` 后，终端会显示一条提示信息并自动打开浏览器
2. 浏览器跳转到 Anthropic 的 OAuth 授权页面
3. 登录你的 Anthropic 账号并点击 **"Authorize"（授权）**
4. 授权成功后，浏览器页面会显示确认信息
5. 返回终端，Claude Code 已自动完成认证，可以直接使用

```
$ claude
? How would you like to authenticate?
❯ Log in with Anthropic (OAuth - recommended)
  Use an API key
  Connect to Claude for Enterprise
```

选择第一项 `Log in with Anthropic` 后，终端会输出：

```
Opening browser to authenticate...
Waiting for authentication...
✅ Successfully authenticated!
```

> **提示：** 如果浏览器未自动打开，手动复制终端中显示的 URL 到浏览器访问即可。

### 3.3 API Key 认证

如果你希望使用 API Key 进行认证（例如在无浏览器的服务器环境中），有两种方式：

**方式一：交互式输入**

```bash
claude
# 选择 "Use an API key"
# 粘贴你的 API Key（以 sk-ant- 开头）
```

**方式二：通过环境变量（推荐用于自动化场景）**

```bash
# 在 ~/.bashrc 或 ~/.zshrc 中添加
export ANTHROPIC_API_KEY="sk-ant-api03-xxxxxxxxxxxxxxxxxxxx"

# 使改动生效
source ~/.bashrc

# 直接启动即可，无需再次认证
claude
```

**方式三：临时使用**

```bash
ANTHROPIC_API_KEY="sk-ant-api03-xxxxx" claude "你好，请帮我查看当前目录结构"
```

### 3.4 认证状态检查

查看当前的认证状态和账号信息：

```bash
claude config
# 会显示当前的认证方式、账号、模型配置等信息
```

如需退出当前登录并重新认证：

```bash
claude logout
claude login
```

---

## 4. CLI 命令速查表

Claude Code 的 CLI 提供了丰富的参数选项，以下是完整的命令标志列表及说明。

### 4.1 基础用法

```bash
# 启动交互式会话
claude

# 直接发送单次提问（非交互模式）
claude "解释一下这段代码的作用"

# 通过管道传入内容
cat error.log | claude "分析这段日志中的错误原因"
```

### 4.2 输出与模式控制

| 标志 | 说明 | 示例 |
|------|------|------|
| `--print` / `-p` | 非交互模式，输出结果后立即退出，不进入对话 | `claude -p "列出所有 TODO"` |
| `--output-format` | 指定输出格式：`text`（默认）、`json`、`stream-json` | `claude -p --output-format json "查看文件"` |
| `--verbose` | 输出详细的调试信息，包括工具调用日志 | `claude --verbose` |
| `--max-turns` | 限制 Agent 的最大轮次（用于自动化场景防止无限循环） | `claude -p --max-turns 10 "重构代码"` |
| `--version` | 显示当前版本号 | `claude --version` |
| `--help` | 显示帮助信息 | `claude --help` |

### 4.3 会话管理

| 标志 | 说明 | 示例 |
|------|------|------|
| `--continue` / `-c` | 继续最近一次的会话对话 | `claude --continue` |
| `--resume` / `-r` | 通过会话 ID 恢复特定的历史会话 | `claude --resume abc123def` |

### 4.4 模型与 Prompt 配置

| 标志 | 说明 | 示例 |
|------|------|------|
| `--model` | 指定使用的模型（覆盖默认配置） | `claude --model claude-sonnet-4-20250514` |
| `--system-prompt` | 自定义系统提示词（仅 `--print` 模式可用） | `claude -p --system-prompt "你是一个代码审查专家" "审查代码"` |
| `--append-system-prompt` | 在默认系统提示词后追加内容 | `claude -p --append-system-prompt "请用中文回答" "explain this"` |
| `--input-format` | 指定输入格式：`text`（默认）、`stream-json` | `claude -p --input-format stream-json` |

### 4.5 工具与权限控制

| 标志 | 说明 | 示例 |
|------|------|------|
| `--allowedTools` | 只允许使用指定的工具（白名单） | `claude --allowedTools "Read,Grep,Glob"` |
| `--disallowedTools` | 禁止使用指定的工具（黑名单） | `claude --disallowedTools "Bash,Write"` |
| `--permission-mode` | 权限模式：`default`、`plan`、`bypassPermissions` | `claude --permission-mode plan` |
| `--dangerously-skip-permissions` | **危险操作：** 跳过所有权限确认（仅限自动化/CI 场景） | `claude --dangerously-skip-permissions -p "run tests"` |

> **严重警告：** `--dangerously-skip-permissions` 会让 Claude Code 在不经任何确认的情况下执行所有操作（包括写文件、运行命令等）。请仅在受控的 CI/CD 环境中使用，**绝对不要在开发机上随意使用**。

### 4.6 综合实战示例

```bash
# 以 JSON 格式输出，限制 5 轮，使用 Sonnet 模型
claude -p \
  --output-format json \
  --max-turns 5 \
  --model claude-sonnet-4-20250514 \
  "分析当前项目的目录结构并给出改进建议"

# 继续上次对话并追加系统提示
claude --continue --append-system-prompt "请注意代码需要兼容 Python 3.8+"

# 只允许读取类工具，做安全的代码审查
claude --allowedTools "Read,Grep,Glob" -p "审查 src/ 目录下的代码质量"
```

---

## 5. 环境变量完整列表

Claude Code 支持通过环境变量来配置各种行为。以下是所有重要环境变量的完整列表：

### 5.1 核心配置

| 环境变量 | 说明 | 示例值 |
|---------|------|--------|
| `ANTHROPIC_API_KEY` | Anthropic API 密钥 | `sk-ant-api03-xxxxxxxx` |
| `ANTHROPIC_MODEL` | 默认使用的模型名称（可被 `--model` 覆盖） | `claude-sonnet-4-20250514` |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | 限制单次响应的最大输出 token 数 | `16384` |
| `CLAUDE_CODE_MAX_MEMORY` | Claude Code 进程可使用的最大内存（MB） | `4096` |

### 5.2 云平台切换

| 环境变量 | 说明 | 示例值 |
|---------|------|--------|
| `CLAUDE_CODE_USE_BEDROCK` | 启用 Amazon Bedrock 作为后端（设为 `1` 启用） | `1` |
| `CLAUDE_CODE_USE_VERTEX` | 启用 Google Vertex AI 作为后端（设为 `1` 启用） | `1` |

### 5.3 网络与代理

| 环境变量 | 说明 | 示例值 |
|---------|------|--------|
| `HTTP_PROXY` | HTTP 代理服务器地址 | `http://proxy.example.com:8080` |
| `HTTPS_PROXY` | HTTPS 代理服务器地址 | `http://proxy.example.com:8080` |
| `NO_PROXY` | 不经过代理的域名列表（逗号分隔） | `localhost,127.0.0.1,.internal.com` |
| `NODE_EXTRA_CA_CERTS` | 自定义 CA 证书路径（用于企业内网 SSL 拦截） | `/etc/ssl/custom-ca.pem` |

### 5.4 功能开关

| 环境变量 | 说明 | 示例值 |
|---------|------|--------|
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | 禁用非必要的网络请求（遥测等） | `1` |
| `DISABLE_PROMPT_CACHING` | 禁用 prompt 缓存（调试用途） | `1` |
| `MCP_TIMEOUT` | MCP 服务器连接超时时间（毫秒） | `30000` |
| `CLAUDE_CODE_SKIP_TELEMETRY` | 跳过遥测数据上报 | `1` |

### 5.5 推荐的 Shell 配置

将常用的环境变量写入 Shell 配置文件中，这样每次启动终端时自动加载：

```bash
# 编辑 ~/.bashrc 或 ~/.zshrc，添加以下内容：

# Claude Code 核心配置
export ANTHROPIC_API_KEY="sk-ant-api03-your-key-here"
export ANTHROPIC_MODEL="claude-sonnet-4-20250514"

# 可选：限制输出 token
export CLAUDE_CODE_MAX_OUTPUT_TOKENS="16384"

# 可选：代理配置（企业网络常用）
# export HTTPS_PROXY="http://proxy.company.com:8080"
# export NO_PROXY="localhost,127.0.0.1"

# 可选：禁用遥测
# export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
```

---

## 6. 云平台支持

除了直接使用 Anthropic API，Claude Code 还支持通过主要云平台来调用模型，适合有合规性要求或已有云平台合同的企业用户。

### 6.1 Amazon Bedrock 配置

Amazon Bedrock 允许你通过 AWS 基础设施来访问 Claude 模型。

**前提条件：**
- 已有 AWS 账号并开通了 Bedrock 中 Claude 模型的访问权限
- 已配置 AWS CLI 凭证（`aws configure`）

**环境变量配置：**

```bash
# 启用 Bedrock 模式（必须）
export CLAUDE_CODE_USE_BEDROCK=1

# AWS 区域（必须）
export AWS_REGION="us-east-1"

# 认证方式一：使用 AWS CLI 默认凭证链（推荐）
# 确保已执行 aws configure 或已设置 IAM 角色

# 认证方式二：显式指定凭证
export AWS_ACCESS_KEY_ID="AKIAxxxxxxxxxxxxxxxx"
export AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# 可选：指定 AWS Profile
export AWS_PROFILE="my-bedrock-profile"

# 可选：跨账号访问 - 使用 Session Token
export AWS_SESSION_TOKEN="xxxxxxxxxx"
```

**启动使用：**

```bash
claude   # 会自动通过 Bedrock 发送请求
```

### 6.2 Google Vertex AI 配置

Google Vertex AI 让你通过 GCP 基础设施访问 Claude 模型。

**前提条件：**
- 已有 GCP 项目并开通 Vertex AI 中 Claude 模型的访问权限
- 已安装并配置 `gcloud` CLI

**环境变量配置：**

```bash
# 启用 Vertex AI 模式（必须）
export CLAUDE_CODE_USE_VERTEX=1

# GCP 项目 ID（必须）
export CLOUD_ML_PROJECT_ID="my-gcp-project-id"

# GCP 区域（必须）
export CLOUD_ML_REGION="us-east5"

# 认证方式一：使用 gcloud 默认凭证（推荐）
gcloud auth application-default login

# 认证方式二：使用服务账号密钥文件
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
```

**启动使用：**

```bash
claude   # 会自动通过 Vertex AI 发送请求
```

### 6.3 Azure AI Foundry 配置（预览）

Azure AI Foundry（原 Azure OpenAI Service 的扩展）也支持 Claude 模型。

**环境变量配置：**

```bash
# 启用 Azure 模式
export CLAUDE_CODE_USE_AZURE=1

# Azure 端点 URL（必须）
export AZURE_ENDPOINT="https://your-resource.services.ai.azure.com"

# Azure API 版本
export AZURE_API_VERSION="2025-01-01"

# 认证方式一：Azure AD（推荐）
# 使用 az login 进行登录即可
az login

# 认证方式二：API Key
export AZURE_API_KEY="your-azure-api-key"
```

### 6.4 云平台选择对照表

| 特性 | Anthropic API 直连 | Amazon Bedrock | Google Vertex AI | Azure AI Foundry |
|------|-------------------|---------------|-----------------|-----------------|
| 启用变量 | 默认 | `CLAUDE_CODE_USE_BEDROCK=1` | `CLAUDE_CODE_USE_VERTEX=1` | `CLAUDE_CODE_USE_AZURE=1` |
| 认证方式 | API Key / OAuth | AWS IAM | GCP IAM | Azure AD / Key |
| 数据驻留 | Anthropic 托管 | AWS 区域内 | GCP 区域内 | Azure 区域内 |
| 适合场景 | 个人开发者、快速上手 | AWS 重度用户、企业合规 | GCP 重度用户、企业合规 | Azure 生态用户 |

---

## 7. 代理与网络配置

在企业网络环境中，你可能需要配置代理才能访问外部 API。

### 7.1 HTTP / HTTPS 代理配置

```bash
# 设置代理
export HTTP_PROXY="http://proxy.company.com:8080"
export HTTPS_PROXY="http://proxy.company.com:8080"

# 排除不需要代理的地址
export NO_PROXY="localhost,127.0.0.1,.company.internal"
```

**带认证的代理：**

```bash
export HTTPS_PROXY="http://username:password@proxy.company.com:8080"
```

> **注意：** 密码中如果包含特殊字符（如 `@`、`#`），需要进行 URL 编码。

### 7.2 自定义 CA 证书

许多企业使用 SSL 拦截代理，这会导致 Node.js 默认拒绝连接。你需要将企业 CA 证书配置到环境中：

```bash
# 指定额外的 CA 证书文件
export NODE_EXTRA_CA_CERTS="/etc/ssl/certs/company-root-ca.pem"
```

**获取企业 CA 证书的方法：**

```bash
# 方法一：从浏览器导出（推荐）
# 在浏览器中访问 https://api.anthropic.com，查看证书链，导出根证书为 PEM 格式

# 方法二：从系统证书中提取
openssl s_client -connect api.anthropic.com:443 -showcerts </dev/null 2>/dev/null \
  | openssl x509 -outform PEM > /tmp/anthropic-ca.pem
```

### 7.3 SOCKS 代理

如果你需要使用 SOCKS5 代理：

```bash
export HTTPS_PROXY="socks5://proxy.company.com:1080"
```

---

## 8. 常见安装问题排查

### 8.1 npm 全局安装权限问题

**错误信息：**

```
npm ERR! Error: EACCES: permission denied, mkdir '/usr/local/lib/node_modules'
```

**解决方案（三选一）：**

```bash
# 方案一（推荐）：更改 npm 全局目录到用户目录
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
npm install -g @anthropic-ai/claude-code

# 方案二：使用 sudo（不推荐，可能引起后续权限混乱）
sudo npm install -g @anthropic-ai/claude-code

# 方案三：使用 nvm 管理 Node.js（nvm 安装的 Node.js 不需要 sudo）
nvm install --lts
npm install -g @anthropic-ai/claude-code
```

### 8.2 Node.js 版本不兼容

**错误信息：**

```
Error: claude-code requires Node.js >= 18.0.0, but found v16.x.x
```

**解决方案：**

```bash
# 检查当前版本
node --version

# 使用 nvm 升级
nvm install 20
nvm use 20
nvm alias default 20

# 确认版本已更新
node --version   # 应输出 v20.x.x

# 重新安装
npm install -g @anthropic-ai/claude-code
```

### 8.3 网络连接问题

**错误信息：**

```
Error: connect ETIMEDOUT api.anthropic.com:443
# 或
FetchError: request to https://api.anthropic.com failed
```

**排查步骤：**

```bash
# 1. 检测是否能访问 Anthropic API
curl -v https://api.anthropic.com

# 2. 检查 DNS 解析
nslookup api.anthropic.com

# 3. 检查代理设置是否正确
echo $HTTPS_PROXY
echo $NO_PROXY

# 4. 如果在企业网络中，尝试配置代理
export HTTPS_PROXY="http://your-proxy:8080"
claude
```

### 8.4 认证失败

**场景一：OAuth 认证失败**

```
Error: Authentication failed - invalid or expired token
```

```bash
# 清除缓存的认证信息，重新登录
claude logout
claude login
```

**场景二：API Key 无效**

```
Error: 401 Unauthorized - Invalid API key
```

```bash
# 检查 API Key 是否正确设置
echo $ANTHROPIC_API_KEY

# 确认 Key 以 sk-ant- 开头并且没有多余空格
# 重新设置
export ANTHROPIC_API_KEY="sk-ant-api03-your-correct-key"
```

**场景三：API Key 权限不足**

```
Error: 403 Forbidden
```

请前往 [Anthropic Console](https://console.anthropic.com/) 检查你的 API Key 是否有足够的权限，以及账户余额是否充足。

### 8.5 WSL2 特定问题（Windows 用户）

**浏览器无法自动打开（OAuth 认证时）：**

```bash
# 确保 WSL2 中配置了 Windows 浏览器
# 在 ~/.bashrc 或 ~/.zshrc 中添加：
export BROWSER="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"

# 或者手动复制终端中的 URL 到 Windows 浏览器打开
```

**路径映射问题：**

```bash
# WSL2 中访问 Windows 文件应使用 /mnt/c/ 前缀
# 建议将项目放在 WSL2 文件系统中（如 ~/projects/），性能更好
cd ~/projects/my-project
claude
```

### 8.6 快速诊断命令汇总

当遇到问题时，按顺序执行以下命令收集诊断信息：

```bash
# 系统环境
node --version
npm --version
which claude
claude --version

# 网络状态
curl -I https://api.anthropic.com
echo "HTTPS_PROXY: $HTTPS_PROXY"
echo "NO_PROXY: $NO_PROXY"

# 认证状态
echo "API Key set: $([ -n \"$ANTHROPIC_API_KEY\" ] && echo 'Yes' || echo 'No')"
echo "Bedrock mode: $CLAUDE_CODE_USE_BEDROCK"
echo "Vertex mode: $CLAUDE_CODE_USE_VERTEX"
```

将以上输出信息一并提供，有助于快速定位问题根源。

---

> ⬅️ [返回总览](Claude-code-guild.md) | ➡️ [下一章：核心工具详解](Claude-code-02-core-tools.md)
