![GitHub License](https://img.shields.io/github/license/Bryce199805/technicalDoc)

# Technical Documentation

A collection of technical documentation and notes covering various topics.

## 目录 / Contents

- [C++](#c)
- [Coding](#coding)
- [Docker](#docker)
- [Git](#git)
- [HyperV](#hyperv)
- [Linux](#linux)
  - [CLI Tools](#cli-tools)
  - [System Admin](#system-admin)
  - [Network](#linux-network)
  - [File Share](#file-share)
- [Markdown](#markdown)
- [Multipass](#multipass)
- [Network](#network)
- [Node.js](#nodejs)
- [TexLive](#texlive)

---

## C++
- [SmartPointer 智能指针](C++/SmartPointer.md)
- [CMakeList Option](C++/CMakeList.md)

## Coding
- [Copilot-api 部署指南](Codeing/Copilot-api.md)
- **Claude Code 完整中文教程**
  - [总览与导读](Codeing/Claude-code-guild.md)
  - [01 — 安装、启动与认证](Codeing/Claude-code-01-install.md)
  - [02 — 核心工具详解](Codeing/Claude-code-02-core-tools.md)
  - [03 — 交互模式完全指南](Codeing/Claude-code-03-interactive.md)
  - [04 — 记忆系统与 CLAUDE.md](Codeing/Claude-code-04-memory.md)
  - [05 — 权限、安全与沙箱](Codeing/Claude-code-05-permissions.md)
  - [06 — 子代理与 Skills](Codeing/Claude-code-06-agents.md)
  - [07 — MCP 服务器与 Hooks](Codeing/Claude-code-07-mcp-hooks.md)
  - [08 — 实战工作流与最佳实践](Codeing/Claude-code-08-workflows.md)

## Docker
- **Docker 完整教程系列**
  - [01 — Docker 基础概念](Docker/01-docker-basics.md)
  - [02 — Docker 安装与配置](Docker/02-docker-installation.md)
  - [03 — Docker 镜像管理](Docker/03-docker-images.md)
  - [04 — Docker 容器管理](Docker/04-docker-containers.md)
  - [05 — Dockerfile 编写指南](Docker/05-dockerfile-guide.md)
  - [06 — Docker 网络管理](Docker/06-docker-network.md)
  - [07 — Docker 数据管理](Docker/07-docker-data-management.md)
  - [08 — Docker Compose 完整指南](Docker/08-docker-compose.md)
  - [09 — Docker 实战案例](Docker/09-docker-practice.md)
  - [10 — Docker 故障排查](Docker/10-docker-troubleshooting.md)

## Git
- [Git Command](Git/git_commend.md)
- [将本地项目关联到git仓库](Git/setup.md)

## HyperV
- [Hyper-V Switch](HyperV/SwitchSetting.md)
- [Static IP Address for Linux](HyperV/StaticIP.md)

## Linux

### CLI Tools
- [终端工具安装清单](Linux/CLI-Tools/00-安装清单.md)
- [快捷安装脚本](Linux/CLI-Tools/install.sh)
- [zsh + Oh My Zsh](Linux/CLI-Tools/01-zsh-ohmyzsh.md)
- [eza 现代化 ls](Linux/CLI-Tools/02-eza.md)
- [bat 现代化 cat](Linux/CLI-Tools/03-bat.md)
- [zoxide 智能目录跳转](Linux/CLI-Tools/04-zoxide.md)
- [fzf 模糊搜索](Linux/CLI-Tools/05-fzf.md)
- [btop 系统监控](Linux/CLI-Tools/06-btop.md)
- [tldr 命令文档](Linux/CLI-Tools/07-tldr.md)
- [Zellij 终端复用](Linux/CLI-Tools/08-zellij.md)
- [Neovim + LazyVim](Linux/CLI-Tools/09-neovim-lazyvim.md)

### System Admin
- [Shell 配置指南 (bash & zsh)](Linux/System-Admin/shell-configuration-guide.md)
- [Cron 定时任务](Linux/System-Admin/cron.md)
- [Systemd Unit 服务管理](Linux/System-Admin/systemd-unit.md)
- [Shutdown 定时关机](Linux/System-Admin/shutdown.md)
- [su & sudo 权限管理](Linux/System-Admin/Root-Permission.md)
- [User & Group 用户组管理](Linux/System-Admin/User-Group.md)

### Linux Network
- [SSH 登录配置](Linux/Network/SSH-Login.md)
- [SSH & SCP 使用](Linux/Network/SSH-SCP.md)
- [SSH Tunnel 隧道](Linux/Network/SSH-Tunnel.md)

### File Share
- [Samba 文件共享](Linux/File-Share/Samba.md)

## Markdown
- **Markdown 语法规范速查**
  - [总览与快速索引](Markdown/README.md)
  - [01 — 基础语法](Markdown/01-基础语法.md)
  - [02 — 文本格式](Markdown/02-文本格式.md)
  - [03 — 表格语法](Markdown/03-表格语法.md)
  - [04 — 数学公式](Markdown/04-数学公式.md) ⭐ 重点
  - [05 — 代码块](Markdown/05-代码块.md)
  - [06 — 扩展语法](Markdown/06-扩展语法.md)
  - [07 — 特殊字符](Markdown/07-特殊字符.md)
  - [08 — 快捷键对照表](Markdown/08-快捷键对照表.md)

## Multipass
- [Ubuntu 轻量级虚拟机](Mutilpass/mutilpass.md)

## Network
- [SSL 证书配置](Network/SSL证书配置.md)
- **NAT Traversal / 内网穿透**
  - [ZeroTier 异地组网](Network/NAT%20Traversal/ZeroTier.md)
  - [FRP 反向代理](Network/NAT%20Traversal/FRP.md)
- **OpenWRT**
  - [OpenWRT 配置](Network/OpenWRT/openwrt.md)
  - [接口选项卡 mwan](Network/OpenWRT/mwan.md)
  - [校园网环境 IPv6 设置](Network/OpenWRT/ipv6.md)
- **VPS Proxy Agent**
  - [IPv6 Only VPS 配置](Network/VPSProxyAgent/IPv6-vps.md)

## Node.js
- **Node.js 开发环境配置**
  - [Node.js 环境完整指南](Node.js/nodejs-environment-guide.md)
  - 包含: nvm、npm、pnpm、yarn、Shell 配置、常见问题解决

## TexLive
- [Tex Live in WSL](TexLive/texLive%20in%20WSL.md)
