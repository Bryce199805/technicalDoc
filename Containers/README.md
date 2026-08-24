# Containers

本目录用于组织容器通用原理、具体实现和工程实践。Docker 是当前主要内容，但容器知识不限定于单一产品。

## 当前内容

| 主题 | 内容 |
|------|------|
| [Docker](Docker/README.md) | Docker 基础、镜像、容器、构建、网络、存储、Compose、实战与排障 |

## 推荐学习路径

1. 先理解 Linux namespace、cgroup、联合文件系统和容器隔离边界。
2. 通过 Docker 掌握镜像、容器、网络和持久化数据。
3. 学习 OCI、镜像仓库、运行时和供应链安全。
4. 再扩展到多主机编排和集群运维。

## 未来扩展

- namespace、cgroup、capabilities、seccomp 与 overlayfs。
- OCI Image/Runtime 规范以及 containerd、runc、Podman。
- Rootless 容器、镜像签名、SBOM 和漏洞扫描。
- 私有 Registry、缓存代理、多架构镜像与 BuildKit。
- Kubernetes 基础、网络、存储、安全和可观测性。
