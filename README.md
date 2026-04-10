![GitHub License](https://img.shields.io/github/license/Bryce199805/technicalDoc) ![Docs](https://img.shields.io/badge/docs-96-blue) ![Topics](https://img.shields.io/badge/topics-12-green)

# Technical Documentation

技术文档与笔记集合，涵盖开发工具、系统运维、网络配置等领域。

---

## 导航

| | | |
|:---:|:---:|:---:|
| [🖥️ C++](#-c) | [🤖 Coding](#-coding) | [🐳 Docker](#-docker) |
| [🔀 Git](#-git) | [💿 HyperV](#-hyperv) | [🐧 Linux](#-linux) |
| [📝 Markdown](#-markdown) | [📦 Multipass](#-multipass) | [🌐 Network](#-network) |
| [🟢 Node.js](#-nodejs) | [📄 TexLive](#-texlive) | [🔥 Torch](#-torch) |

---

## 🖥️ C++

| 文档 | 说明 |
|------|------|
| [SmartPointer](C++/SmartPointer.md) | 智能指针 |
| [CMakeList](C++/CMakeList.md) | CMake 选项配置 |

---

## 🤖 Coding

| 文档 | 说明 |
|------|------|
| [Copilot-api](Codeing/Copilot-api.md) | Copilot API 部署指南 |

**Claude Code 中文教程**

| 文档 | 说明 |
|------|------|
| [总览与导读](Codeing/Claude-code-guild.md) | 教程概览与学习路线 |
| [安装、启动与认证](Codeing/Claude-code-01-install.md) | 环境准备与首次运行 |
| [核心工具详解](Codeing/Claude-code-02-core-tools.md) | 文件操作、搜索等核心能力 |
| [交互模式完全指南](Codeing/Claude-code-03-interactive.md) | 交互方式与快捷操作 |
| [记忆系统与 CLAUDE.md](Codeing/Claude-code-04-memory.md) | 上下文记忆与项目配置 |
| [权限、安全与沙箱](Codeing/Claude-code-05-permissions.md) | 安全模型与权限控制 |
| [子代理与 Skills](Codeing/Claude-code-06-agents.md) | 多代理协作与技能扩展 |
| [MCP 服务器与 Hooks](Codeing/Claude-code-07-mcp-hooks.md) | 外部集成与钩子机制 |
| [实战工作流与最佳实践](Codeing/Claude-code-08-workflows.md) | 高效使用策略与案例 |

---

## 🐳 Docker

**系列教程**

| 文档 | 说明 |
|------|------|
| [Docker 基础概念](Docker/01-docker-basics.md) | 核心概念与架构 |
| [Docker 安装与配置](Docker/02-docker-installation.md) | 各平台安装步骤 |
| [Docker 镜像管理](Docker/03-docker-images.md) | 镜像拉取、构建与清理 |
| [Docker 容器管理](Docker/04-docker-containers.md) | 容器生命周期管理 |
| [Dockerfile 编写指南](Docker/05-dockerfile-guide.md) | 指令详解与最佳实践 |
| [Docker 网络管理](Docker/06-docker-network.md) | 网络模式与配置 |
| [Docker 数据管理](Docker/07-docker-data-management.md) | 卷与绑定挂载 |
| [Docker Compose 完整指南](Docker/08-docker-compose.md) | 多容器编排 |
| [Docker 实战案例](Docker/09-docker-practice.md) | 真实场景应用 |
| [Docker 故障排查](Docker/10-docker-troubleshooting.md) | 常见问题与诊断 |

**参考笔记**

| 文档 | 说明 |
|------|------|
| [Docker 安装笔记](Docker/docker%20install.md) | 安装过程记录 |
| [Docker 代理配置](Docker/docker%20proxy.md) | 网络代理设置 |
| [Dockerfile 笔记](Docker/dockerfile.md) | 编写要点备忘 |
| [Docker Compose 笔记](Docker/docker-compose.md) | Compose 用法速查 |
| [Docker 命令速查](Docker/dockers%20commend.md) | 常用命令参考 |
| [Docker 网络](Docker/Docker%20Network.md) | 网络配置补充 |

---

## 🔀 Git

**系列教程**

| 文档 | 说明 |
|------|------|
| [Git 基础入门](Git/Git基础入门.md) | 基本概念、环境配置、首次使用 |
| [Git 日常操作](Git/Git日常操作.md) | 常用命令和工作流程 |
| [Git 分支管理](Git/Git分支管理.md) | 分支策略、合并与冲突解决 |
| [Git 高级技巧](Git/Git高级技巧.md) | 重置、暂存、子模块等高级功能 |
| [Git 协作流程](Git/Git协作流程.md) | 远程仓库操作、团队协作 |
| [Git 提交规范](Git/Git提交规范.md) | Commit Message 最佳实践 |
| [Git 常见问题](Git/Git常见问题.md) | 错误排查和解决方案 |

**参考笔记**

| 文档 | 说明 |
|------|------|
| [Git Command](Git/git_commend.md) | 命令速查参考 |
| [Git 仓库设置](Git/setup.md) | 项目初始化与关联远程 |

---

## 💿 HyperV

| 文档 | 说明 |
|------|------|
| [Hyper-V Switch](HyperV/SwitchSetting.md) | 虚拟交换机配置 |
| [Static IP for Linux](HyperV/StaticIP.md) | Linux 虚拟机静态 IP |

---

## 🐧 Linux

### CLI Tools 终端工具

| 文档 | 说明 |
|------|------|
| [终端工具安装清单](Linux/CLI-Tools/00-安装清单.md) | 工具总览与快速安装 |
| [zsh + Oh My Zsh](Linux/CLI-Tools/01-zsh-ohmyzsh.md) | Shell 美化与增强 |
| [eza 现代化 ls](Linux/CLI-Tools/02-eza.md) | 彩色文件列表 |
| [bat 现代化 cat](Linux/CLI-Tools/03-bat.md) | 语法高亮查看 |
| [zoxide 智能目录跳转](Linux/CLI-Tools/04-zoxide.md) | 基于频率的 cd |
| [fzf 模糊搜索](Linux/CLI-Tools/05-fzf.md) | 全局模糊查找 |
| [btop 系统监控](Linux/CLI-Tools/06-btop.md) | 资源监控面板 |
| [tldr 命令文档](Linux/CLI-Tools/07-tldr.md) | 简化版 man |
| [Zellij 终端复用](Linux/CLI-Tools/08-zellij.md) | 现代终端复用器 |
| [Neovim + LazyVim](Linux/CLI-Tools/09-neovim-lazyvim.md) | IDE 级编辑器 |

### KVM 虚拟化

| 文档 | 说明 |
|------|------|
| [虚拟化原理](Linux/KVM-Virtualization/01-principles.md) | KVM/QEMU/libvirt 架构 |
| [环境安装](Linux/KVM-Virtualization/02-installation.md) | 软件包与权限配置 |
| [虚拟网络](Linux/KVM-Virtualization/03-networking.md) | NAT/桥接/端口转发 |
| [创建虚拟机](Linux/KVM-Virtualization/04-vm-creation.md) | 磁盘与安装方式 |
| [虚拟机管理](Linux/KVM-Virtualization/05-vm-management.md) | 生命周期与资源调整 |
| [快照管理](Linux/KVM-Virtualization/06-snapshots.md) | 创建、恢复与删除 |
| [存储管理](Linux/KVM-Virtualization/07-storage.md) | 存储池与磁盘格式 |
| [远程访问](Linux/KVM-Virtualization/08-remote-access.md) | 串口/SSH/VNC |
| [安全加固](Linux/KVM-Virtualization/09-security.md) | 网络隔离与沙箱 |
| [故障排查](Linux/KVM-Virtualization/10-troubleshooting.md) | 诊断命令与日志 |
| [命令速查](Linux/KVM-Virtualization/11-command-reference.md) | 按场景分类的命令 |

### System Admin 系统管理

| 文档 | 说明 |
|------|------|
| [Shell 配置指南](Linux/System-Admin/shell-configuration-guide.md) | bash & zsh 配置 |
| [Cron 定时任务](Linux/System-Admin/cron.md) | 计划任务管理 |
| [Systemd Unit](Linux/System-Admin/systemd-unit.md) | 服务管理 |
| [Shutdown 定时关机](Linux/System-Admin/shutdown.md) | 关机与重启 |
| [su & sudo](Linux/System-Admin/Root-Permission.md) | 权限提升 |
| [User & Group](Linux/System-Admin/User-Group.md) | 用户组管理 |

### Network 网络配置

| 文档 | 说明 |
|------|------|
| [SSH 登录配置](Linux/Network/SSH-Login.md) | 密钥登录与安全加固 |
| [SSH & SCP](Linux/Network/SSH-SCP.md) | 远程拷贝 |
| [SSH Tunnel](Linux/Network/SSH-Tunnel.md) | 隧道与端口转发 |

### File Share 文件共享

| 文档 | 说明 |
|------|------|
| [Samba](Linux/File-Share/Samba.md) | 跨平台文件共享 |

---

## 📝 Markdown

| 文档 | 说明 |
|------|------|
| [总览与快速索引](Markdown/README.md) | 语法索引 |
| [基础语法](Markdown/01-基础语法.md) | 标题、段落、链接 |
| [文本格式](Markdown/02-文本格式.md) | 加粗、斜体、删除线 |
| [表格语法](Markdown/03-表格语法.md) | 对齐与复杂表格 |
| [数学公式](Markdown/04-数学公式.md) | LaTeX 公式 |
| [代码块](Markdown/05-代码块.md) | 语法高亮与行号 |
| [扩展语法](Markdown/06-扩展语法.md) | 脚注、任务列表 |
| [特殊字符](Markdown/07-特殊字符.md) | 实体与符号 |
| [快捷键对照表](Markdown/08-快捷键对照表.md) | 编辑器快捷键 |

---

## 📦 Multipass

| 文档 | 说明 |
|------|------|
| [Ubuntu 轻量级虚拟机](Mutilpass/mutilpass.md) | Multipass 安装与使用 |

---

## 🌐 Network

| 文档 | 说明 |
|------|------|
| [Nginx](Network/Nginx.md) | Nginx 配置 |
| [SSL 证书配置](Network/SSL证书配置.md) | HTTPS 证书部署 |

**NAT Traversal 内网穿透**

| 文档 | 说明 |
|------|------|
| [ZeroTier](Network/NAT%20Traversal/ZeroTier.md) | 异地组网 |
| [FRP](Network/NAT%20Traversal/FRP.md) | 反向代理穿透 |

**OpenWRT**

| 文档 | 说明 |
|------|------|
| [OpenWRT 配置](Network/OpenWRT/openwrt.md) | 路由器基础配置 |
| [mwan 接口选项卡](Network/OpenWRT/mwan.md) | 多线负载均衡 |
| [校园网 IPv6](Network/OpenWRT/ipv6.md) | IPv6 穿透设置 |

**VPS Proxy Agent**

| 文档 | 说明 |
|------|------|
| [IPv6 Only VPS](Network/VPSProxyAgent/IPv6-vps.md) | 纯 IPv6 VPS 配置 |

---

## 🟢 Node.js

| 文档 | 说明 |
|------|------|
| [Node.js 环境完整指南](Node.js/nodejs-environment-guide.md) | nvm/npm/pnpm/yarn 配置与使用 |

---

## 📄 TexLive

| 文档 | 说明 |
|------|------|
| [TexLive in WSL](TexLive/texLive%20in%20WSL.md) | WSL 中安装 LaTeX |

---

## 🔥 Torch

| 文档 | 说明 |
|------|------|
| [CUDA 安装](Torch/CUDA/cuda-install.md) | CUDA 驱动与工具包安装 |

---

## License

[MIT](LICENSE) Copyright 2024 Bryce
