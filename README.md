# Technical Documentation

面向开发、Linux 系统与基础设施实践的中文技术知识库。目录按稳定的技术主题组织，学习顺序和跨主题关系由各级 README 维护。

## 知识领域

| 领域 | 当前内容 | 入口 |
|------|----------|------|
| Linux | 命令行工具、系统管理、CGroup 与 systemd Slice | [Linux](Linux/README.md) |
| Network | SSH、Nginx、TLS、OpenWrt、内网穿透、文件共享、VPS 网络 | [Network](Network/README.md) |
| Virtualization | KVM/QEMU/libvirt、Hyper-V、Multipass | [Virtualization](Virtualization/README.md) |
| Containers | Docker 基础、镜像、容器、网络、存储、Compose 与排障 | [Containers](Containers/README.md) |
| GPU | Linux GPU 驱动、DKMS、CUDA 环境 | [GPU](GPU/README.md) |
| Git | Git 入门、分支、协作、提交规范与故障排查 | [Git](Git/README.md) |
| C++ | C++ 语言特性与 CMake 构建笔记 | [C++](C++/README.md) |
| Node.js | Node.js 版本和包管理环境 | [Node.js](Node.js/README.md) |
| AI Coding | Claude Code 系列教程与 Copilot API | [AI Coding](AI-Coding/README.md) |
| Markdown | Markdown 基础、扩展语法、公式和编辑器速查 | [Markdown](Markdown/README.md) |
| TeX Live | LaTeX/TeX Live 环境配置 | [TeX Live](TexLive/README.md) |

## 推荐学习路线

### Linux 与基础设施

1. [Linux](Linux/README.md)：先掌握命令行、权限、服务和资源管理。
2. [Network](Network/README.md)：补齐远程访问、路由、代理和网络服务。
3. [Virtualization](Virtualization/README.md)：理解完整虚拟机的计算、网络和存储。
4. [Containers](Containers/README.md)：学习容器原理与 Docker 工程实践。
5. [GPU](GPU/README.md)：在系统、容器和驱动基础上构建 GPU 计算环境。

### 开发与协作

1. [Git](Git/README.md)：建立版本控制和团队协作基础。
2. [C++](C++/README.md) 或 [Node.js](Node.js/README.md)：进入对应语言和运行时生态。
3. [Containers](Containers/README.md)：固化开发、测试与部署环境。
4. [AI Coding](AI-Coding/README.md)：在已有工程实践上使用 AI 辅助开发。

### 技术写作

1. [Markdown](Markdown/README.md)：完成日常说明、知识笔记和项目文档。
2. [TeX Live](TexLive/README.md)：扩展到论文、公式密集型和 PDF 排版场景。

## 未来扩展顺序

1. 优先补齐 Linux 和 Network 的基础原理，让现有运维笔记拥有稳定前置知识。
2. 在 Containers 中加入容器通用原理、OCI、运行时和安全，再扩展到集群编排。
3. 在 Virtualization 中补充自动化、性能、设备直通和迁移，在 GPU 中延伸到性能分析与 PyTorch。
4. 将 C++ 和 Node.js 从环境或单点笔记扩展为完整语言与工程实践路线。
5. 为快速变化的 AI Coding 内容建立版本验证、评测和安全治理方法。
6. 按各目录 README 的规划逐步补充内容，避免提前创建没有正文的空目录。

## 组织原则

- 一级目录使用直观、稳定的技术主题，不按“初级、进阶、实战”划分目录。
- 顺序性强的系列使用编号文件；独立主题使用描述性文件名。
- 同一知识点保留一个主要入口，其他场景通过相关链接引用。
- 图片和可复现的示例配置跟随所属主题存放。
- 个人偏好、草稿、模板和本地工具状态不进入远端仓库。

## License

[MIT](LICENSE) Copyright 2024 Bryce
