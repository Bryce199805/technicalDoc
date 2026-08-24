# Docker

本目录包含一套按顺序学习的 Docker 教程，以及早期积累的专题速查笔记。

## 系列教程

| 顺序 | 文档 | 内容 |
|------|------|------|
| 1 | [Docker 基础概念](01-docker-basics.md) | 架构、核心对象、底层技术和适用场景 |
| 2 | [Docker 安装与配置](02-docker-installation.md) | 多平台安装、服务配置和卸载 |
| 3 | [Docker 镜像管理](03-docker-images.md) | 拉取、构建、标签、导入导出和清理 |
| 4 | [Docker 容器管理](04-docker-containers.md) | 生命周期、资源、日志和进程管理 |
| 5 | [Dockerfile 编写指南](05-dockerfile-guide.md) | 指令、多阶段构建和最佳实践 |
| 6 | [Docker 网络管理](06-docker-network.md) | 网络模式、DNS、端口映射和调试 |
| 7 | [Docker 数据管理](07-docker-data-management.md) | Volume、Bind Mount、备份和存储驱动 |
| 8 | [Docker Compose 完整指南](08-docker-compose.md) | 多容器应用定义与环境组织 |
| 9 | [Docker 实战案例](09-docker-practice.md) | 数据库、Web、消息队列、监控和日志服务 |
| 10 | [Docker 故障排查](10-docker-troubleshooting.md) | 服务、容器、网络、存储和性能诊断 |

## 专题笔记

| 文档 | 内容 |
|------|------|
| [安装笔记](docker%20install.md) | 早期安装命令记录 |
| [代理配置](docker%20proxy.md) | Docker 网络代理 |
| [Dockerfile 笔记](dockerfile.md) | Dockerfile 速查 |
| [Compose 笔记](docker-compose.md) | Compose 配置速查 |
| [命令速查](dockers%20commend.md) | 常用 Docker 命令 |
| [网络补充](Docker%20Network.md) | Docker 网络示例 |

专题笔记与系列教程有重叠，后续应逐步合并到对应权威章节，避免同一主题出现两套结论。

## 推荐学习路径

按 01–08 顺序完成基础学习，通过 09 建立完整应用，再使用 10 形成排障闭环。学习网络和资源限制时，分别关联 [Network](../../Network/README.md) 与 [CGroup](../../Linux/System-Admin/CGroup/README.md)。

## 未来扩展

- BuildKit、构建缓存、多架构镜像和远程 Builder。
- Registry、镜像生命周期、签名、SBOM 和漏洞扫描。
- Rootless Docker、Capabilities、seccomp 和安全基线。
- 日志驱动、指标、事件和生产可观测性。
- Docker 与 containerd、Podman、Kubernetes 的边界。
