# Virtualization

本目录集中记录虚拟化原理及 KVM、Hyper-V、Multipass 的使用。不同实现共享计算、网络、存储、镜像和生命周期管理等基础概念。

## 当前内容

| 平台 | 入口 | 内容 |
|------|------|------|
| KVM/QEMU/libvirt | [KVM](KVM/README.md) | 原理、安装、网络、创建、管理、存储、安全和排障 |
| Hyper-V | [Hyper-V](Hyper-V/README.md) | 虚拟交换机和 Linux 虚拟机静态 IP |
| Multipass | [Multipass](Multipass/README.md) | Ubuntu 轻量虚拟机安装与日常管理 |

## 推荐学习路径

1. 理解 Hypervisor、硬件虚拟化、设备模拟和半虚拟化。
2. 选择一个平台完成虚拟机创建、网络和远程访问。
3. 学习镜像、快照、存储、备份和资源管理。
4. 再扩展到自动化创建、模板化和迁移。

## 未来扩展

- Type 1/Type 2 Hypervisor、CPU/内存虚拟化和 virtio。
- cloud-init、镜像模板、自动化安装和批量管理。
- PCI/GPU Passthrough、NUMA 和性能调优。
- 备份恢复、跨主机迁移、高可用和容量规划。
- KVM、Hyper-V、Multipass 与容器的适用场景对比。
