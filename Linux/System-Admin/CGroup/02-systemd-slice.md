# Systemd Slice 实战

systemd slice 是 systemd 对 cgroup 树的高级抽象。它用于把 service、scope、用户会话、虚拟机、容器等 unit 组织到资源层级中，并统一配置 CPU、内存、IO、进程数等限制。

如果你最近在用 slice 管理服务器资源，重点应该掌握三个问题：

- slice 在 systemd 中如何命名和嵌套。
- 服务如何被放入指定 slice。
- slice 与 service 上的资源限制如何叠加。

## unit、slice、service、scope 的关系

systemd 管理的对象统称 unit。与资源管理关系最密切的是下面几类：

| unit 类型 | 后缀 | 作用 |
|-----------|------|------|
| slice | `.slice` | 资源分组，不直接启动进程 |
| service | `.service` | systemd 启动和管理的服务进程 |
| scope | `.scope` | systemd 接管但不是 systemd 启动的进程组 |
| user service | `.service` | 用户级 systemd 服务，通常位于 `user.slice` 下 |

slice 负责“分组与资源边界”，service/scope 负责“实际进程”。

## 默认 slice 层级

多数 systemd 系统默认有三个重要 slice：

| slice | 用途 |
|-------|------|
| `system.slice` | 系统服务默认位置，例如 `sshd.service`、`nginx.service` |
| `user.slice` | 用户登录会话、用户级 systemd 服务 |
| `machine.slice` | 虚拟机、容器、nspawn machine 等对象 |

查看当前树：

```shell
systemd-cgls
```

查看资源占用：

```shell
systemd-cgtop
```

查看某个服务位置：

```shell
systemctl show nginx.service -p Slice -p ControlGroup
```

## slice 命名规则

slice 名称表达层级。`-` 会被 systemd 解释为父子关系。

| slice 名称 | 层级含义 |
|------------|----------|
| `apps.slice` | `/apps.slice` |
| `apps-web.slice` | `/apps.slice/apps-web.slice` |
| `apps-web-api.slice` | `/apps.slice/apps-web.slice/apps-web-api.slice` |

注意：slice 文件名中的 `-` 不是普通字符，而是层级分隔。不要随意用 `-` 表达普通命名语义。

例如你想表达“后台任务”，推荐：

```text
batch.slice
```

如果你想表达“应用下面的后台任务”，可以用：

```text
apps-batch.slice
```

它实际表示：

```text
apps.slice
└── apps-batch.slice
```

## 创建 slice

创建 `/etc/systemd/system/apps.slice`：

```ini
[Unit]
Description=Application Services Slice
Documentation=man:systemd.resource-control(5)

[Slice]
CPUWeight=200
MemoryHigh=12G
MemoryMax=16G
IOWeight=200
TasksMax=20000
```

加载配置：

```shell
systemctl daemon-reload
systemctl start apps.slice
systemctl status apps.slice
```

slice 通常不需要 `enable`，它会在有 unit 使用时自动出现。但如果你希望开机就创建，也可以启用：

```shell
systemctl enable apps.slice
```

## 把服务放入 slice

### 在 service 文件中指定

```ini
[Unit]
Description=Example API Service

[Service]
ExecStart=/opt/example-api/bin/server
Slice=apps.slice
Restart=always

[Install]
WantedBy=multi-user.target
```

### 用 drop-in 覆盖已有服务

推荐对发行版或软件包自带服务使用 drop-in，不直接修改原始 unit。

```shell
systemctl edit nginx.service
```

写入：

```ini
[Service]
Slice=apps-web.slice
CPUWeight=300
MemoryHigh=2G
MemoryMax=3G
TasksMax=4096
```

应用：

```shell
systemctl daemon-reload
systemctl restart nginx.service
systemctl show nginx.service -p Slice -p ControlGroup -p CPUWeight -p MemoryHigh -p MemoryMax -p TasksMax
```

注意：`Slice=` 通常需要重启服务才能移动到新 slice。

## 临时运行受限任务

`systemd-run` 非常适合做实验或运行一次性任务。

```shell
systemd-run --unit=backup-job --slice=batch.slice -p CPUQuota=50% -p MemoryMax=2G /usr/local/bin/backup.sh
```

运行一个交互 shell：

```shell
systemd-run --scope --slice=batch.slice -p CPUWeight=50 -p MemoryMax=1G bash
```

查看：

```shell
systemctl status backup-job.service
systemctl show backup-job.service -p ControlGroup
systemd-cgls batch.slice
```

## slice 与 service 限制如何叠加

slice 是父级，service 是子级。限制遵循父子层级。

例如：

```ini
# apps.slice
[Slice]
MemoryMax=16G
CPUWeight=200
```

```ini
# api.service
[Service]
Slice=apps.slice
MemoryMax=4G
CPUWeight=300
```

含义：

- `api.service` 自身最多使用 4G 内存。
- `apps.slice` 下所有服务合计最多使用 16G 内存。
- `api.service` 的 `CPUWeight=300` 只和 `apps.slice` 下其他兄弟 unit 比较。
- `apps.slice` 的 `CPUWeight=200` 只和根层级下其他兄弟 slice 比较，例如 `system.slice`、`user.slice`。

## 常见资源参数

| systemd 参数 | 底层 cgroup v2 文件 | 说明 |
|--------------|---------------------|------|
| `CPUWeight=` | `cpu.weight` | CPU 相对权重 |
| `CPUQuota=` | `cpu.max` | CPU 硬配额 |
| `AllowedCPUs=` | `cpuset.cpus` | 允许使用的 CPU 核 |
| `MemoryHigh=` | `memory.high` | 内存高水位，触发回收和限流 |
| `MemoryMax=` | `memory.max` | 内存硬上限 |
| `MemorySwapMax=` | `memory.swap.max` | swap 使用上限 |
| `IOWeight=` | `io.weight` | IO 相对权重 |
| `IOReadBandwidthMax=` | `io.max` | 读带宽硬限制 |
| `IOWriteBandwidthMax=` | `io.max` | 写带宽硬限制 |
| `TasksMax=` | `pids.max` | 最大 task 数量 |

完整参数参考 `man systemd.resource-control`。

## 推荐的服务器 slice 规划

一个清晰的服务器资源模型可以这样设计：

```text
-.slice
├── system.slice              # 系统基础服务
├── user.slice                # 用户登录和用户服务
├── machine.slice             # 容器、虚拟机
├── critical.slice            # 关键业务
├── apps.slice                # 普通业务服务
│   ├── apps-web.slice
│   └── apps-worker.slice
├── batch.slice               # 批处理、备份、构建
└── observability.slice       # 监控、日志、agent
```

建议：

- `critical.slice` 用较高 `CPUWeight`，谨慎设置硬限制。
- `batch.slice` 可以设置 `CPUQuota`、`IOWeight`、`MemoryMax`，防止后台任务冲击系统。
- `observability.slice` 不要限制过死，否则故障时反而丢监控和日志。
- `user.slice` 适合设置 `TasksMax` 和适度内存限制，避免登录用户误操作。
- 容器和虚拟机通常放在 `machine.slice`，不要随意和普通服务混放。

## 示例：隔离备份任务

创建 `/etc/systemd/system/batch.slice`：

```ini
[Unit]
Description=Batch Jobs Slice

[Slice]
CPUWeight=50
CPUQuota=200%
MemoryHigh=4G
MemoryMax=6G
IOWeight=50
TasksMax=5000
```

创建备份服务：

```ini
[Unit]
Description=Nightly Backup Job

[Service]
Type=oneshot
Slice=batch.slice
ExecStart=/usr/local/sbin/nightly-backup
CPUWeight=30
IOWeight=30

[Install]
WantedBy=multi-user.target
```

解释：

- `batch.slice` 整体最多使用 2 个 CPU 核的时间，因为 `CPUQuota=200%`。
- `MemoryHigh=4G` 达到后会触发内存回收和限流。
- `MemoryMax=6G` 是硬上限，超过后可能 OOM。
- `IOWeight=50` 表示有 IO 竞争时优先级较低。

## 示例：保护关键业务

创建 `/etc/systemd/system/critical.slice`：

```ini
[Unit]
Description=Critical Services Slice

[Slice]
CPUWeight=1000
MemoryHigh=20G
IOWeight=1000
TasksMax=30000
```

把核心服务放入该 slice：

```shell
systemctl edit payment-api.service
```

写入：

```ini
[Service]
Slice=critical.slice
CPUWeight=1000
MemoryHigh=8G
MemoryMax=10G
IOWeight=1000
TasksMax=10000
```

解释：

- `critical.slice` 在根层级与其他 slice 竞争时拥有更高权重。
- service 自身也有资源边界，避免单个关键服务吃掉整个关键资源池。
- 关键服务不建议一开始设置太低的 `CPUQuota`，否则会人为制造延迟上限。

## 修改配置后的标准流程

```shell
# 1. 修改 unit 或 drop-in 后重新加载 systemd
systemctl daemon-reload

# 2. 如果修改了 Slice=，通常需要重启服务
systemctl restart example.service

# 3. 查看最终配置
systemctl cat example.service
systemctl show example.service -p Slice -p ControlGroup -p CPUWeight -p CPUQuotaPerSecUSec -p MemoryHigh -p MemoryMax -p IOWeight -p TasksMax

# 4. 查看 cgroup 树
systemd-cgls

# 5. 查看实时占用
systemd-cgtop
```

## 常见问题

### 修改 Slice 后为什么不生效

`Slice=` 决定进程启动时放入哪个 cgroup。已经运行的服务通常不会因为 daemon-reload 自动迁移，需要重启服务。

### 为什么 service 设置的 CPUWeight 没有效果

`CPUWeight` 只在 CPU 竞争时体现。如果系统 CPU 空闲，看起来可能没有任何限制效果。要验证权重，需要制造同级竞争负载。

### 为什么 CPUQuota 设置后吞吐明显下降

`CPUQuota` 是硬上限，服务即使有空闲 CPU 也不能突破。延迟敏感服务应优先考虑 `CPUWeight`，只有明确需要封顶时再用 `CPUQuota`。

### 为什么 MemoryMax 导致服务被杀

`MemoryMax` 是硬上限。服务超过限制后，内核会在该 cgroup 内触发 OOM。先查看：

```shell
journalctl -u example.service -b
systemctl show example.service -p MemoryCurrent -p MemoryPeak -p MemoryMax
cat /sys/fs/cgroup/<path>/memory.events
```

## 下一步

继续阅读 [资源控制参数详解](03-resource-control.md)，系统掌握 CPU、内存、IO、PID 等参数的含义和配置策略。
