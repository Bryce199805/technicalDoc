# 资源控制参数详解

systemd 的资源控制参数最终会映射到 cgroup 控制器。理解这些参数的语义，比记住命令更重要。尤其要区分“硬限制”“软限制”“权重”“亲和性”和“统计值”。

## 配置位置

资源控制参数可以写在不同 unit 类型中。

### slice

```ini
[Slice]
CPUWeight=200
MemoryHigh=8G
MemoryMax=12G
IOWeight=200
TasksMax=10000
```

### service

```ini
[Service]
Slice=apps.slice
CPUQuota=150%
MemoryMax=2G
TasksMax=2048
```

### scope

scope 通常通过 `systemd-run --scope` 或上层程序创建：

```shell
systemd-run --scope -p MemoryMax=1G -p CPUWeight=50 make -j8
```

## CPU 控制

### CPUWeight

`CPUWeight=` 控制 CPU 相对权重，范围通常是 `1` 到 `10000`，默认值常见为 `100`。

示例：

```ini
[Service]
CPUWeight=300
```

适合场景：

- 关键服务比普通服务更优先。
- 后台任务可以利用空闲 CPU，但有竞争时自动让路。
- 不想给服务设置硬上限，但希望影响调度倾向。

不适合场景：

- 想严格限制服务最多只能使用几个核心。
- 想让服务在没有竞争时也不能用满 CPU。

验证：

```shell
systemctl show example.service -p CPUWeight
cat /sys/fs/cgroup/<path>/cpu.weight
```

### CPUQuota

`CPUQuota=` 设置 CPU 硬配额。

```ini
[Service]
CPUQuota=50%
```

含义：最多使用半个 CPU 核的时间。

```ini
[Service]
CPUQuota=200%
```

含义：最多使用两个 CPU 核的时间。

注意：

- `CPUQuota=100%` 不等于“允许用满所有 CPU”，而是大约 1 个 CPU 核。
- 对多线程服务设置过低会造成吞吐和延迟下降。
- CPU 空闲时也不能突破配额。

### CPUQuotaPeriodSec

`CPUQuotaPeriodSec=` 设置 CPU 配额周期。

```ini
[Service]
CPUQuota=200%
CPUQuotaPeriodSec=100ms
```

一般不需要修改周期。周期过长可能造成突发，周期过短可能增加调度开销。

### AllowedCPUs

`AllowedCPUs=` 限制服务能运行在哪些 CPU 核上。

```ini
[Service]
AllowedCPUs=0-3
```

适合场景：

- 将延迟敏感服务固定在特定 CPU 核。
- 给批处理任务限制到一组核心。
- NUMA 或性能调优场景。

注意：CPU 亲和性不是性能万能药。错误绑定可能导致负载不均、缓存争用或 NUMA 远端访问。

### StartupCPUWeight 与 StartupCPUQuota

这些参数只影响服务启动阶段。

```ini
[Service]
StartupCPUWeight=50
CPUWeight=300
```

适合防止大量服务同时启动时抢占系统资源。

## 内存控制

内存控制是生产中最容易出事故的部分。建议优先理解 `MemoryHigh` 和 `MemoryMax` 的区别。

### MemoryCurrent 与 MemoryPeak

这两个是统计值，不是限制值。

```shell
systemctl show example.service -p MemoryCurrent -p MemoryPeak
```

### MemoryHigh

`MemoryHigh=` 是高水位。超过后内核会对该 cgroup 进行更积极的回收和限流，但不一定立即杀进程。

```ini
[Service]
MemoryHigh=2G
```

适合场景：

- 希望服务超过某个内存水平后变慢，而不是马上死亡。
- 给批处理、缓存型服务设置软边界。
- 生产中先观察服务在压力下的行为。

建议：

- 对不熟悉的服务先设置 `MemoryHigh`，观察 `memory.events` 中的 `high` 计数。
- 如果 `high` 频繁增长且延迟升高，说明高水位太低或服务确实需要更多内存。

### MemoryMax

`MemoryMax=` 是内存硬上限。

```ini
[Service]
MemoryMax=3G
```

超过限制后，内核会在该 cgroup 内触发 OOM，可能杀掉服务进程。

适合场景：

- 防止低优先级任务拖垮整机。
- 限制已知内存上界的服务。
- 多租户环境中提供强边界。

风险：

- 服务可能因为短暂峰值被杀。
- JVM、数据库、缓存服务容易因为内部内存管理与 cgroup 限制不匹配而异常。
- OOM 后如果 `Restart=always`，可能进入反复重启。

### MemoryLow 与 MemoryMin

`MemoryLow=` 是内存保护，表示系统内存压力下尽量不要回收这部分内存。

```ini
[Service]
MemoryLow=1G
```

`MemoryMin=` 是更强的保护。一般生产中应谨慎使用，因为过多 `MemoryMin` 会导致系统整体回收困难。

适合场景：

- 给关键服务保留最低内存保护。
- 防止重要服务在全局内存压力下被过度回收。

### MemorySwapMax

控制 swap 使用上限。

```ini
[Service]
MemorySwapMax=0
```

含义：禁止该服务使用 swap。

注意：

- 禁止 swap 可以降低延迟抖动，但更容易 OOM。
- 对批处理任务允许适量 swap 可能更稳。
- 对数据库是否禁用 swap 需要结合数据库自身建议。

### OOMPolicy

`OOMPolicy=` 控制服务内进程被 OOM 后 systemd 如何处理 unit。

```ini
[Service]
OOMPolicy=stop
```

常见值：

| 值 | 行为 |
|----|------|
| `continue` | 继续运行 unit 中剩余进程 |
| `stop` | 停止整个 unit |
| `kill` | 杀掉整个 unit 的进程 |

对单进程服务通常 `stop` 或 `kill` 更容易理解。对多进程服务要谨慎评估。

## IO 控制

IO 控制主要影响块设备。不同内核、调度器、文件系统和设备类型下效果可能不同。cgroup v2 中主要使用 `io` 控制器。

如果维护的是 cgroup v1 或混合模式系统，并且需要直接写 `/sys/fs/cgroup/blkio/*/blkio.throttle.*` 文件限制某个问题进程，请阅读 [CGroup v1 blkio 手工限速](06-cgroup-v1-blkio-manual.md)。

### IOWeight

`IOWeight=` 控制 IO 相对权重。

```ini
[Service]
IOWeight=50
```

适合场景：

- 备份、日志压缩、批处理任务降低 IO 优先级。
- 数据库或关键服务提高 IO 权重。

注意：权重只在 IO 竞争时体现。

### IOReadBandwidthMax 与 IOWriteBandwidthMax

限制读写带宽。

```ini
[Service]
IOReadBandwidthMax=/dev/nvme0n1 100M
IOWriteBandwidthMax=/dev/nvme0n1 50M
```

适合场景：

- 限制备份任务读取磁盘。
- 限制日志归档写入速度。
- 防止单个服务冲击共享块设备。

获取设备：

```shell
lsblk
findmnt /var/lib/example
```

### IOReadIOPSMax 与 IOWriteIOPSMax

限制每秒 IO 次数。

```ini
[Service]
IOReadIOPSMax=/dev/nvme0n1 1000
IOWriteIOPSMax=/dev/nvme0n1 500
```

适合 IOPS 敏感的共享磁盘环境。

## PID 与任务数控制

### TasksMax

`TasksMax=` 限制 unit 中最大 task 数量，包括进程和线程。

```ini
[Service]
TasksMax=2048
```

适合场景：

- 防止 fork bomb。
- 限制用户会话或批处理任务。
- 避免服务异常创建大量线程。

查看：

```shell
systemctl show example.service -p TasksCurrent -p TasksMax
cat /sys/fs/cgroup/<path>/pids.current
cat /sys/fs/cgroup/<path>/pids.max
```

注意：Java、Go、Node.js、数据库和高并发服务都可能创建较多线程。设置前先观察峰值。

## 设备访问控制

systemd 还可以通过 `DevicePolicy=`、`DeviceAllow=` 等参数控制设备访问。

```ini
[Service]
DevicePolicy=closed
DeviceAllow=/dev/null rw
DeviceAllow=/dev/random r
DeviceAllow=/dev/urandom r
```

这类配置更接近安全加固，不只是资源管理。错误配置可能导致服务无法启动。

## 常用组合策略

### 延迟敏感 Web/API 服务

```ini
[Service]
CPUWeight=500
MemoryHigh=2G
MemoryMax=3G
IOWeight=500
TasksMax=4096
```

策略：用权重保证竞争时优先，不轻易设置 CPU 硬上限。

### 后台批处理任务

```ini
[Service]
CPUWeight=50
CPUQuota=100%
MemoryHigh=2G
MemoryMax=4G
IOWeight=50
TasksMax=2048
```

策略：明确封顶 CPU 和内存，降低 IO 权重。

### 备份任务

```ini
[Service]
CPUWeight=30
CPUQuota=50%
MemoryMax=1G
IOReadBandwidthMax=/dev/nvme0n1 100M
IOWriteBandwidthMax=/dev/nvme0n1 50M
```

策略：主要限制 CPU 与磁盘带宽，避免业务高峰被备份冲击。

### 用户登录会话

可以通过 `user-.slice` 或 `user@.service` 设置用户资源限制，但要先了解发行版默认配置。

示例 drop-in：

```ini
[Slice]
TasksMax=4096
MemoryHigh=4G
MemoryMax=6G
```

策略：防止误操作和进程爆炸，不要过度影响正常运维。

## 参数选择建议

| 目标 | 首选参数 | 谨慎使用 |
|------|----------|----------|
| 提高关键服务竞争优先级 | `CPUWeight`、`IOWeight`、`MemoryLow` | `CPUQuota` |
| 限制后台任务影响 | `CPUQuota`、`IOWeight`、`MemoryHigh` | 过低 `MemoryMax` |
| 防止内存拖垮整机 | `MemoryHigh`、`MemoryMax` | `MemoryMin` |
| 防止进程爆炸 | `TasksMax` | 过低限制 |
| 固定 CPU 核 | `AllowedCPUs` | 随意绑核 |
| 限制磁盘冲击 | `IOReadBandwidthMax`、`IOWriteBandwidthMax` | 不确认设备路径就配置 |

## 查看最终生效值

systemd 可能有默认值、全局配置、slice 配置、service 配置、drop-in 覆盖。查看最终值应使用：

```shell
systemctl cat example.service
systemctl show example.service \
  -p Slice \
  -p ControlGroup \
  -p CPUWeight \
  -p CPUQuotaPerSecUSec \
  -p AllowedCPUs \
  -p MemoryCurrent \
  -p MemoryPeak \
  -p MemoryHigh \
  -p MemoryMax \
  -p MemorySwapMax \
  -p IOWeight \
  -p TasksCurrent \
  -p TasksMax
```

如果需要对照底层 cgroup 文件：

```shell
CGROUP=$(systemctl show example.service -p ControlGroup --value)
cd /sys/fs/cgroup"$CGROUP"
cat cpu.weight cpu.max memory.current memory.high memory.max pids.current pids.max
```

## 下一步

继续阅读 [观测与故障排查](04-observability-troubleshooting.md)，学习如何判断限制是否生效、服务是否被 cgroup OOM、资源瓶颈在哪里。
