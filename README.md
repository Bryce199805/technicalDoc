![GitHub License](https://img.shields.io/github/license/Bryce199805/technicalDoc) ![Docs](https://img.shields.io/badge/docs-124-blue) ![Topics](https://img.shields.io/badge/topics-11-green)

# Technical Documentation

开发、Linux 系统与基础设施相关的中文技术文档。本页是当前仓库的总目录和快速入口；各主题的学习顺序与未来扩展方向请查看对应目录内的 `README.md`。

## 导航

| 一级目录 | 当前内容 | 入口 |
|----------|----------|------|
| C++ | 智能指针、CMake | [进入 C++](C++/README.md) |
| AI-Coding | Claude Code、Copilot API | [进入 AI-Coding](AI-Coding/README.md) |
| Containers | Docker | [进入 Containers](Containers/README.md) |
| Git | 基础、分支、协作、提交与排障 | [进入 Git](Git/README.md) |
| Linux | 命令行工具、系统管理、CGroup | [进入 Linux](Linux/README.md) |
| Markdown | 基础语法、扩展语法、公式与快捷键 | [进入 Markdown](Markdown/README.md) |
| Network | SSH、Nginx、TLS、内网穿透、OpenWrt、文件共享、VPS | [进入 Network](Network/README.md) |
| Node.js | Node.js 开发环境 | [进入 Node.js](Node.js/README.md) |
| GPU | GPU 驱动、DKMS、CUDA | [进入 GPU](GPU/README.md) |
| TexLive | WSL 中的 TeX Live | [进入 TexLive](TexLive/README.md) |
| Virtualization | KVM、Hyper-V、Multipass | [进入 Virtualization](Virtualization/README.md) |

## [C++](C++/README.md)

| 文档 | 内容 |
|------|------|
| [SmartPointer](C++/SmartPointer.md) | C++ 智能指针 |
| [CMakeList](C++/CMakeList.md) | CMake 条件与配置笔记 |

## [AI-Coding](AI-Coding/README.md)

| 文档 | 内容 |
|------|------|
| [Claude Code 教程总览](AI-Coding/Claude-code-guild.md) | Claude Code 系列教程入口 |
| [01 安装、启动与认证](AI-Coding/Claude-code-01-install.md) | 安装、认证、环境变量与网络配置 |
| [02 核心工具](AI-Coding/Claude-code-02-core-tools.md) | 文件、搜索、命令与 Web 工具 |
| [03 交互模式](AI-Coding/Claude-code-03-interactive.md) | 命令、快捷键、会话与模型切换 |
| [04 记忆系统](AI-Coding/Claude-code-04-memory.md) | `CLAUDE.md`、规则与上下文管理 |
| [05 权限、安全与沙箱](AI-Coding/Claude-code-05-permissions.md) | 权限模式、配置与安全边界 |
| [06 子代理与 Skills](AI-Coding/Claude-code-06-agents.md) | 子代理、Skills 与协作机制 |
| [07 MCP 与 Hooks](AI-Coding/Claude-code-07-mcp-hooks.md) | MCP 服务与 Hooks 生命周期 |
| [08 实战工作流](AI-Coding/Claude-code-08-workflows.md) | Git、CI/CD、IDE 与工程实践 |
| [Copilot API](AI-Coding/Copilot-api.md) | Copilot API 部署指南 |

## [Containers](Containers/README.md)

### [Docker](Containers/Docker/README.md)

| 文档 | 内容 |
|------|------|
| [01 基础概念](Containers/Docker/01-docker-basics.md) | Docker 架构与核心对象 |
| [02 安装与配置](Containers/Docker/02-docker-installation.md) | Docker 安装、权限与基础配置 |
| [03 镜像管理](Containers/Docker/03-docker-images.md) | 镜像获取、构建与维护 |
| [04 容器管理](Containers/Docker/04-docker-containers.md) | 容器生命周期与常用操作 |
| [05 Dockerfile](Containers/Docker/05-dockerfile-guide.md) | Dockerfile 编写指南 |
| [06 网络管理](Containers/Docker/06-docker-network.md) | Docker 网络模型与配置 |
| [07 数据管理](Containers/Docker/07-docker-data-management.md) | Volume、Bind Mount 与数据持久化 |
| [08 Docker Compose](Containers/Docker/08-docker-compose.md) | Compose 配置与多容器编排 |
| [09 实战案例](Containers/Docker/09-docker-practice.md) | Docker 综合实践 |
| [10 故障排查](Containers/Docker/10-docker-troubleshooting.md) | 常见问题诊断与处理 |
| [Docker 安装笔记](<Containers/Docker/docker install.md>) | Docker 安装旧笔记 |
| [Docker 代理](<Containers/Docker/docker proxy.md>) | Daemon 与容器代理配置 |
| [Dockerfile 笔记](Containers/Docker/dockerfile.md) | Dockerfile 参考笔记 |
| [Docker Compose 笔记](Containers/Docker/docker-compose.md) | Compose 参考笔记 |
| [Docker 命令速记](<Containers/Docker/dockers commend.md>) | 常用 Docker 命令 |
| [Docker Network 笔记](<Containers/Docker/Docker Network.md>) | Docker 网络参考笔记 |

## [Git](Git/README.md)

| 文档 | 内容 |
|------|------|
| [Git 基础入门](Git/Git基础入门.md) | 仓库、提交与基础概念 |
| [Git 日常操作](Git/Git日常操作.md) | 日常开发命令与流程 |
| [Git 分支管理](Git/Git分支管理.md) | 分支创建、合并与维护 |
| [Git 协作流程](Git/Git协作流程.md) | 团队协作工作流 |
| [Git 提交规范](Git/Git提交规范.md) | Commit Message 约定 |
| [Git 高级技巧](Git/Git高级技巧.md) | 进阶操作与历史处理 |
| [Git 常见问题](Git/Git常见问题.md) | 常见故障与解决方案 |
| [Git 命令笔记](Git/git_commend.md) | 配置与命令速记 |
| [关联远程仓库](Git/setup.md) | 本地项目关联 Git 仓库 |

## [Linux](Linux/README.md)

### [CLI-Tools](Linux/CLI-Tools/README.md)

| 文档 | 内容 |
|------|------|
| [00 安装清单](Linux/CLI-Tools/00-安装清单.md) | 工具、脚本与安装入口 |
| [01 zsh + Oh My Zsh](Linux/CLI-Tools/01-zsh-ohmyzsh.md) | Shell 环境与插件配置 |
| [02 eza](Linux/CLI-Tools/02-eza.md) | 文件列表工具 |
| [03 bat](Linux/CLI-Tools/03-bat.md) | 文件查看工具 |
| [04 zoxide](Linux/CLI-Tools/04-zoxide.md) | 智能目录跳转 |
| [05 fzf](Linux/CLI-Tools/05-fzf.md) | 模糊搜索工具 |
| [06 btop](Linux/CLI-Tools/06-btop.md) | 系统资源监控 |
| [07 tldr](Linux/CLI-Tools/07-tldr.md) | 命令用法速查 |
| [08 Zellij](Linux/CLI-Tools/08-zellij.md) | 终端复用工具 |
| [09 Neovim + LazyVim](Linux/CLI-Tools/09-neovim-lazyvim.md) | 编辑器环境配置 |
| [LazyVim 安装器](Linux/CLI-Tools/lazyvim-installer/README.md) | 安装脚本说明 |
| [LazyVim 练习指南](Linux/CLI-Tools/lazyvim-installer/LEARNING.md) | 新手操作练习 |

### [System-Admin](Linux/System-Admin/README.md)

| 文档 | 内容 |
|------|------|
| [Shell 配置](Linux/System-Admin/shell-configuration-guide.md) | zsh 与 bash 配置 |
| [Cron](Linux/System-Admin/cron.md) | 定时运行 Python 任务 |
| [Systemd Unit](Linux/System-Admin/systemd-unit.md) | Systemd 服务单元 |
| [Shutdown](Linux/System-Admin/shutdown.md) | 关机命令笔记 |
| [Root Permission](Linux/System-Admin/Root-Permission.md) | `su`、`sudo` 与权限 |
| [User Group](Linux/System-Admin/User-Group.md) | Linux 用户组管理 |

#### [CGroup](Linux/System-Admin/CGroup/README.md)

| 文档 | 内容 |
|------|------|
| [01 基础原理](Linux/System-Admin/CGroup/01-cgroup-principles.md) | CGroup 核心概念与版本差异 |
| [02 Systemd Slice](Linux/System-Admin/CGroup/02-systemd-slice.md) | Slice 层级与实战 |
| [03 资源控制](Linux/System-Admin/CGroup/03-resource-control.md) | CPU、内存与 I/O 参数 |
| [04 观测与排障](Linux/System-Admin/CGroup/04-observability-troubleshooting.md) | 指标观测和故障定位 |
| [05 生产实践](Linux/System-Admin/CGroup/05-production-playbook.md) | 生产环境操作手册 |
| [06 CGroup v1 blkio](Linux/System-Admin/CGroup/06-cgroup-v1-blkio-manual.md) | blkio 手工限速 |

## [Markdown](Markdown/README.md)

| 文档 | 内容 |
|------|------|
| [01 基础语法](Markdown/01-基础语法.md) | 标题、列表、链接与图片 |
| [02 文本格式](Markdown/02-文本格式.md) | 强调、引用与文本样式 |
| [03 表格语法](Markdown/03-表格语法.md) | 表格书写与对齐 |
| [04 数学公式](Markdown/04-数学公式.md) | LaTeX 数学公式参考 |
| [05 代码块](Markdown/05-代码块.md) | 行内代码与围栏代码块 |
| [06 扩展语法](Markdown/06-扩展语法.md) | 常见 Markdown 扩展 |
| [07 特殊字符](Markdown/07-特殊字符.md) | 转义与特殊字符 |
| [08 快捷键](Markdown/08-快捷键对照表.md) | Markdown 编辑器快捷键 |

## [Network](Network/README.md)

### 通用服务

| 文档 | 内容 |
|------|------|
| [Nginx](Network/Nginx.md) | Nginx 配置与运维 |
| [SSL 证书](Network/SSL证书配置.md) | 证书申请与 TLS 配置 |

### [SSH](Network/SSH/README.md)

| 文档 | 内容 |
|------|------|
| [SSH 登录](Network/SSH/SSH-Login.md) | 登录与认证配置 |
| [SSH 与 SCP](Network/SSH/SSH-SCP.md) | 远程命令和文件传输 |
| [SSH Tunnel](Network/SSH/SSH-Tunnel.md) | SSH 端口转发与隧道 |

### [NAT-Traversal](Network/NAT-Traversal/README.md)

| 文档或配置 | 内容 |
|------------|------|
| [FRP](Network/NAT-Traversal/FRP.md) | FRP 内网穿透 |
| [FRP 客户端配置](Network/NAT-Traversal/frpc.toml) | `frpc.toml` 示例 |
| [FRP 服务端配置](Network/NAT-Traversal/frps.toml) | `frps.toml` 示例 |
| [ZeroTier](Network/NAT-Traversal/ZeroTier.md) | ZeroTier 异地组网 |

### [OpenWrt](Network/OpenWrt/README.md)

| 文档 | 内容 |
|------|------|
| [OpenWrt](Network/OpenWrt/openwrt.md) | OpenWrt 配置笔记 |
| [Multi-WAN](Network/OpenWrt/mwan.md) | 多 WAN 配置 |
| [IPv6](Network/OpenWrt/ipv6.md) | IPv6 配置笔记 |

### [File-Sharing](Network/File-Sharing/README.md)

| 文档 | 内容 |
|------|------|
| [Samba](Network/File-Sharing/Samba.md) | Linux 与 Windows 文件共享 |

### [VPS](Network/VPS/README.md)

| 文档 | 内容 |
|------|------|
| [IPv6-only VPS](Network/VPS/IPv6-vps.md) | IPv6-only VPS 网络配置 |

## [Node.js](Node.js/README.md)

| 文档 | 内容 |
|------|------|
| [Node.js 开发环境](Node.js/nodejs-environment-guide.md) | 版本管理、包管理器与项目环境 |

## [GPU](GPU/README.md)

### [CUDA](GPU/CUDA/README.md)

| 文档 | 内容 |
|------|------|
| [GPU 驱动与 DKMS](GPU/CUDA/gpu-driver-dkms.md) | Linux GPU 驱动、兼容性、安全启动、容器与排障 |
| [CUDA Toolkit 安装](GPU/CUDA/cuda-install.md) | 无 sudo 权限安装 CUDA Toolkit |

## [TexLive](TexLive/README.md)

| 文档 | 内容 |
|------|------|
| [TeX Live in WSL](<TexLive/texLive in WSL.md>) | WSL 中安装和配置 TeX Live |

## [Virtualization](Virtualization/README.md)

### [KVM](Virtualization/KVM/README.md)

| 文档 | 内容 |
|------|------|
| [01 虚拟化原理](Virtualization/KVM/01-principles.md) | KVM、QEMU 与 libvirt 基础 |
| [02 安装与验证](Virtualization/KVM/02-installation.md) | 环境部署和能力验证 |
| [03 网络管理](Virtualization/KVM/03-networking.md) | NAT、桥接与虚拟网络 |
| [04 创建虚拟机](Virtualization/KVM/04-vm-creation.md) | 虚拟机创建流程 |
| [05 虚拟机管理](Virtualization/KVM/05-vm-management.md) | 生命周期与配置管理 |
| [06 快照管理](Virtualization/KVM/06-snapshots.md) | 快照创建与恢复 |
| [07 存储管理](Virtualization/KVM/07-storage.md) | 存储池与虚拟磁盘 |
| [08 远程访问](Virtualization/KVM/08-remote-access.md) | 控制台与远程连接 |
| [09 安全加固](Virtualization/KVM/09-security.md) | 权限、隔离与安全配置 |
| [10 故障排查](Virtualization/KVM/10-troubleshooting.md) | 常见问题诊断 |
| [11 命令速查](Virtualization/KVM/11-command-reference.md) | KVM 与 libvirt 命令参考 |

### [Hyper-V](Virtualization/Hyper-V/README.md)

| 文档 | 内容 |
|------|------|
| [Static IP](Virtualization/Hyper-V/StaticIP.md) | Linux 虚拟机静态 IP |
| [Switch Setting](Virtualization/Hyper-V/SwitchSetting.md) | Hyper-V 虚拟交换机配置 |

### [Multipass](Virtualization/Multipass/README.md)

| 文档 | 内容 |
|------|------|
| [Multipass](Virtualization/Multipass/multipass.md) | Ubuntu 轻量级虚拟机使用笔记 |

## License

[MIT](LICENSE) Copyright 2024 Bryce
