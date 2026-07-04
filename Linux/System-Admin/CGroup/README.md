# CGroup 与 Systemd Slice 资源管理

本目录用于系统学习 Linux cgroup 资源控制，以及在服务器上通过 systemd slice 管理 CPU、内存、IO、进程数等资源的方法。

## 学习路径

| 顺序 | 文档 | 适合场景 |
|------|------|----------|
| 1 | [CGroup 基础原理](01-cgroup-principles.md) | 先理解 cgroup 是什么、v1/v2 区别、控制器与层级结构 |
| 2 | [Systemd Slice 实战](02-systemd-slice.md) | 重点学习 slice、service、scope 如何组织服务器资源 |
| 3 | [资源控制参数详解](03-resource-control.md) | 查询 CPU、内存、IO、PID、设备等限制参数怎么配置 |
| 4 | [观测与故障排查](04-observability-troubleshooting.md) | 查看某个服务属于哪个 cgroup、限制是否生效、为什么 OOM |
| 5 | [生产实践手册](05-production-playbook.md) | 直接套用服务器分层、资源配额、变更流程和配置模板 |
| 6 | [CGroup v1 blkio 手工限速](06-cgroup-v1-blkio-manual.md) | 维护手工 `blkio.throttle.*`、设备号和 PID 迁移操作 |

## 核心概念速览

| 概念 | 说明 |
|------|------|
| cgroup | Control Group，Linux 内核提供的进程分组和资源控制机制 |
| controller | 资源控制器，例如 `cpu`、`memory`、`io`、`pids`、`cpuset` |
| cgroup v1 | 旧架构，每个控制器可以有独立层级，灵活但复杂 |
| cgroup v2 | 新架构，统一层级，接口一致，现代发行版与 systemd 推荐使用 |
| systemd slice | systemd 对 cgroup 层级的抽象，用于给一组 unit 划分资源边界 |
| service | systemd 管理的长期服务，通常对应一个守护进程 |
| scope | systemd 管理的外部进程组，例如登录会话、临时命令、容器运行时创建的进程 |
| delegation | 将某个 cgroup 子树的管理权委托给容器运行时等下级管理器 |

## 典型使用场景

- 把数据库、业务服务、批处理任务、监控组件分别放入不同 slice，避免互相抢占资源。
- 限制低优先级任务的 CPU 和 IO，保证核心业务服务延迟稳定。
- 给用户登录会话设置进程数和内存边界，防止单个用户拖垮服务器。
- 使用 `systemd-run --slice=` 临时运行一个受限任务。
- 在 cgroup v1 历史系统中手工创建 `blkio` 子组，临时限制问题进程的磁盘 IOPS 或带宽。
- 分析服务 OOM、CPU 打满、IO 抖动、进程数耗尽等问题。
- 为容器运行时、虚拟化、CI runner、构建任务规划资源隔离层级。

## 快速命令

```shell
# 查看当前系统使用 cgroup v1 还是 v2
stat -fc %T /sys/fs/cgroup

# 查看 systemd 管理的 cgroup 树
systemd-cgls

# 查看 unit 的资源占用
systemd-cgtop

# 查看某个服务的 cgroup 路径
systemctl show nginx.service -p ControlGroup

# 临时创建一个受限任务
systemd-run --unit=demo-job --slice=batch.slice -p MemoryMax=1G -p CPUQuota=50% sleep 300

# 查看 slice 配置
systemctl cat batch.slice

# 修改服务资源限制
systemctl edit nginx.service
```

## 建议掌握顺序

1. 先确认服务器是 cgroup v2 还是混合模式。
2. 理解 systemd 的默认层级：`-.slice`、`system.slice`、`user.slice`、`machine.slice`。
3. 从 `CPUWeight`、`MemoryMax`、`MemoryHigh`、`IOWeight`、`TasksMax` 这些高频参数开始。
4. 使用 `systemd-run` 做临时实验，不要一开始就改生产服务。
5. 建立自己的 slice 分层，例如 `critical.slice`、`apps.slice`、`batch.slice`。
6. 对生产服务使用 drop-in 配置，变更前后记录 `systemctl show` 与监控数据。

## 注意事项

- cgroup 是资源控制机制，不是完整安全沙箱；安全隔离仍需要权限、namespace、seccomp、SELinux/AppArmor 等机制配合。
- `CPUQuota=50%` 是硬限制，`CPUWeight=` 是相对权重；两者含义不同。
- `MemoryMax=` 是硬上限，超出后可能触发 OOM；`MemoryHigh=` 更适合作为优雅限流阈值。
- systemd 配置项会被翻译为 cgroup 文件，不建议同时手工改 `/sys/fs/cgroup` 和 systemd unit。
- 资源限制要先在测试环境压测，避免把数据库、日志、监控组件限制得过紧。
