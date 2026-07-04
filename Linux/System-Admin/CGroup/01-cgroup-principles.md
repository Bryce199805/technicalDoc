# CGroup 基础原理

cgroup 是 Linux 内核的 Control Group 机制，用于把进程组织成树状分组，并对这些分组应用资源统计、限制、优先级和隔离策略。现代 Linux 服务器上的 systemd、Docker、containerd、Kubernetes、libvirt、用户登录会话、批处理任务都大量依赖 cgroup。

## cgroup 解决什么问题

传统 Linux 进程模型只知道进程、线程、用户、进程组、会话等概念。它们可以表达“谁启动了谁”，但很难表达下面这些资源管理问题：

- 某个服务最多只能使用 4 GiB 内存。
- 某类后台任务只能在 CPU 空闲时多跑，不能抢核心服务资源。
- 某个用户最多创建 2000 个进程。
- 某个服务组的 IO 权重低于数据库。
- 统计某个应用整体消耗了多少 CPU、内存、IO，而不是只看单个进程。
- 杀掉某个服务时，需要同时清理它派生出来的所有子进程。

cgroup 的核心能力就是“按进程组管理资源”，而不是只按单个进程管理。

## 基本组成

### cgroup 层级

cgroup 以目录树形式呈现。每个目录代表一个 cgroup 节点，进程可以被放进某个节点。子节点会继承父节点的一部分资源边界。

在 cgroup v2 中，统一挂载点通常是：

```shell
/sys/fs/cgroup
```

systemd 管理的服务器上常见结构类似：

```text
/sys/fs/cgroup/
├── system.slice/
│   ├── ssh.service/
│   └── nginx.service/
├── user.slice/
│   └── user-1000.slice/
└── machine.slice/
    └── machine-qemu\x2dvm.scope/
```

### controller 控制器

controller 是内核提供的资源控制模块。常见控制器如下：

| 控制器 | 作用 |
|--------|------|
| `cpu` | CPU 时间分配、权重、配额、压力统计 |
| `cpuset` | 限定可使用的 CPU 核和 NUMA 节点 |
| `memory` | 内存限制、回收、OOM 行为、swap 控制 |
| `io` | 块设备 IO 权重、限速、统计 |
| `pids` | 限制进程和线程数量 |
| `devices` | 设备访问控制，cgroup v2 中主要通过 eBPF 实现 |
| `hugetlb` | HugeTLB 大页资源限制 |
| `rdma` | RDMA 资源限制 |
| `misc` | 其他杂项资源限制 |

不是所有内核和发行版都启用所有控制器。可以通过下面命令查看：

```shell
cat /sys/fs/cgroup/cgroup.controllers
```

### task 与 process

Linux 内核中调度单位是 task。用户看到的“进程”和“线程”在内核里都可以是 task。cgroup 限制通常会影响一个 cgroup 内的所有 task。

查看当前 shell 所在的 cgroup：

```shell
cat /proc/self/cgroup
```

查看某个进程所在的 cgroup：

```shell
cat /proc/<PID>/cgroup
```

在 cgroup v2 中，输出通常类似：

```text
0::/user.slice/user-1000.slice/session-3.scope
```

含义是该进程位于统一层级的 `/user.slice/user-1000.slice/session-3.scope`。

## cgroup v1 与 v2

### cgroup v1

cgroup v1 的特点是每个 controller 可以有独立挂载点和独立层级。例如 `cpu`、`memory`、`blkio` 可以分别组织进程。这让 v1 非常灵活，但也带来复杂性：

- 同一个进程可能在不同控制器下属于不同层级。
- 很难整体理解一个服务的资源归属。
- controller 行为不统一，接口命名和语义不一致。
- 容器运行时、systemd、手工配置之间容易互相冲突。

v1 常见路径：

```text
/sys/fs/cgroup/cpu/
/sys/fs/cgroup/memory/
/sys/fs/cgroup/blkio/
```

### cgroup v2

cgroup v2 使用统一层级，所有 controller 都挂在一棵树下。现代 systemd 默认优先使用 cgroup v2。

v2 的优势：

- 一棵树表达所有资源归属，结构清晰。
- controller 接口更一致。
- 更适合 systemd、容器和编排系统统一管理。
- 增加 `memory.high`、压力统计、统一 IO 控制等能力。
- 避免 v1 中多个层级之间的资源语义冲突。

判断当前系统类型：

```shell
stat -fc %T /sys/fs/cgroup
```

常见结果：

| 输出 | 含义 |
|------|------|
| `cgroup2fs` | cgroup v2 统一层级 |
| `tmpfs` | 通常是 cgroup v1 或混合模式 |

也可以查看挂载信息：

```shell
findmnt -T /sys/fs/cgroup
mount | grep cgroup
```

## cgroup v2 的重要文件

进入某个 cgroup 目录后，会看到很多控制文件。以下是常见文件：

| 文件 | 作用 |
|------|------|
| `cgroup.controllers` | 当前节点可用的控制器 |
| `cgroup.subtree_control` | 当前节点向子节点开放哪些控制器 |
| `cgroup.procs` | 当前 cgroup 中的进程 ID |
| `cgroup.threads` | 当前 cgroup 中的线程 ID |
| `cgroup.events` | 当前 cgroup 状态事件 |
| `cpu.max` | CPU 硬配额 |
| `cpu.weight` | CPU 相对权重 |
| `cpu.stat` | CPU 使用统计 |
| `memory.current` | 当前内存使用量 |
| `memory.high` | 内存软限制或限流阈值 |
| `memory.max` | 内存硬上限 |
| `memory.events` | 内存高水位、OOM 等事件统计 |
| `io.stat` | 块设备 IO 统计 |
| `io.weight` | IO 权重 |
| `pids.current` | 当前进程和线程数量 |
| `pids.max` | 最大进程和线程数量 |

## 父子层级规则

cgroup 不是简单地给某个进程贴标签，它是一棵资源树。理解父子关系非常重要。

### 子节点不能突破父节点限制

如果父 slice 总共限制 `MemoryMax=8G`，其下面的服务即使单独设置 `MemoryMax=16G`，也不能实际使用超过父层级允许的资源。

### 权重只在同级之间比较

`CPUWeight=200` 并不表示获得 200% CPU，也不表示绝对优先级。它只表示同一个父 cgroup 下的兄弟节点之间如何分配 CPU。

例如同一父节点下：

```text
app-a.slice CPUWeight=100
app-b.slice CPUWeight=300
```

在 CPU 竞争时，`app-b.slice` 大约能获得 `app-a.slice` 三倍的 CPU 时间。但如果 CPU 空闲，`app-a.slice` 也可以使用更多 CPU。

### 硬限制与软策略不同

| 类型 | 示例 | 特点 |
|------|------|------|
| 硬限制 | `memory.max`、`cpu.max`、`pids.max` | 超出后直接限制、失败或触发 OOM |
| 软策略 | `cpu.weight`、`io.weight`、`memory.high` | 发生竞争时影响分配，不一定马上阻止使用 |

## systemd 与 cgroup 的关系

systemd 是多数 Linux 发行版的 init 系统，也是 cgroup 的主要用户空间管理器。它会为 unit 创建 cgroup，并把服务进程放入对应路径。

常见映射：

| systemd 概念 | cgroup 表现 |
|--------------|-------------|
| `system.slice` | 系统服务默认所在 slice |
| `user.slice` | 用户登录会话和用户服务所在 slice |
| `machine.slice` | 虚拟机、容器等 machine 对象所在 slice |
| `nginx.service` | `/system.slice/nginx.service` |
| `session-3.scope` | 某个登录会话的进程组 |

查看映射：

```shell
systemctl status nginx.service
systemctl show nginx.service -p ControlGroup
systemd-cgls
```

## 为什么不建议直接手工操作 cgroup 文件

虽然 cgroup 的底层接口就是 `/sys/fs/cgroup` 中的文件，但在 systemd 管理的系统上，推荐通过 systemd 配置资源限制。

原因：

- systemd 会在服务重启、daemon-reload、unit 重新加载时重新应用配置。
- 手工写入 cgroup 文件容易被 systemd 覆盖。
- systemd 能正确处理进程迁移、服务生命周期、依赖关系和日志。
- unit 配置更容易版本化、审计和回滚。

只有在调试内核行为、开发运行时、分析容器底层问题时，才建议直接查看或短暂写入 cgroup 文件。

## 常见误区

### 误区一：cgroup 可以提升服务器总性能

cgroup 不会创造额外 CPU、内存或 IO。它只能改变资源分配方式，避免低优先级任务影响关键任务。

### 误区二：设置 CPUWeight 就是限制 CPU 上限

`CPUWeight` 是权重，不是上限。如果没有竞争，低权重服务仍然可以用满 CPU。要设置上限应使用 `CPUQuota`。

### 误区三：MemoryMax 越严格越安全

过低的 `MemoryMax` 会导致服务频繁 OOM，甚至触发级联故障。生产中更推荐先用 `MemoryHigh` 观察和限流，再谨慎设置 `MemoryMax`。

### 误区四：所有资源都适合硬限制

核心服务通常适合保底和优先级策略，后台任务适合硬限制。对数据库、消息队列、日志系统等状态服务设置硬限制时要特别谨慎。

## 推荐阅读顺序

理解本篇后，继续阅读 [Systemd Slice 实战](02-systemd-slice.md)，重点掌握如何用 slice 把抽象的 cgroup 能力落地为可维护的服务器资源管理方案。
