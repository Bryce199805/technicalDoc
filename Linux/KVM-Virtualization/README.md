# KVM/QEMU/libvirt 虚拟化使用手册

> 适用环境：无图形化界面的 Ubuntu Server，使用命令行管理虚拟机

---

## 手册结构

| 文档 | 内容 |
|------|------|
| [01-principles.md](01-principles.md) | 虚拟化原理：KVM、QEMU、libvirt、virtio 的工作机制 |
| [02-installation.md](02-installation.md) | 环境安装：软件包安装、权限配置、服务验证 |
| [03-networking.md](03-networking.md) | 虚拟网络：NAT、隔离网络、桥接网络、端口转发、Docker 冲突处理 |
| [04-vm-creation.md](04-vm-creation.md) | 创建虚拟机：磁盘创建、两种安装方式、ISO 处理、OS 变体选择 |
| [05-vm-management.md](05-vm-management.md) | 虚拟机管理：生命周期、配置修改、资源调整、删除 |
| [06-snapshots.md](06-snapshots.md) | 快照管理：创建、恢复、删除、最佳实践 |
| [07-storage.md](07-storage.md) | 存储管理：存储池、磁盘格式、扩容、迁移 |
| [08-remote-access.md](08-remote-access.md) | 远程访问：串口控制台、SSH、VNC、X11 转发 |
| [09-security.md](09-security.md) | 安全加固：网络隔离、沙箱、AppArmor、安全等级 |
| [10-troubleshooting.md](10-troubleshooting.md) | 故障排查：常见问题、诊断命令、日志分析 |
| [11-command-reference.md](11-command-reference.md) | 命令速查：按场景分类的常用命令 |

---

## 快速入门

如果你是第一次使用，建议按以下顺序阅读：

1. **01-principles.md** — 了解虚拟化各组件的职责
2. **02-installation.md** — 安装环境并验证
3. **03-networking.md** — 配置虚拟网络
4. **04-vm-creation.md** — 创建你的第一台虚拟机
5. **08-remote-access.md** — 连接到虚拟机

其余文档按需查阅。

---

## 核心架构一览

```
用户空间
═══════════════════════════════════════════
  virsh / virt-install / virt-manager
         │
      libvirtd (守护进程)
         │
      QEMU 进程 (每个虚拟机一个)
         │  通过 /dev/kvm 与内核交互
═════════╪═════════════════════════════════
内核空间 │
         ▼
      KVM 模块 (kvm.ko + kvm_intel.ko / kvm_amd.ko)
         │
      CPU 硬件虚拟化 (Intel VT-x / AMD-V)
═══════════════════════════════════════════
硬件
```
