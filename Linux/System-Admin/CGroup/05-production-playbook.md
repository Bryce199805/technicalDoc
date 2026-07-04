# 生产实践手册

本篇面向实际服务器资源管理，给出 slice 分层设计、配置模板、变更流程、风险控制和常见服务建议。目标是让 cgroup 与 systemd slice 成为可维护的生产工具，而不是一次性命令。

## 设计原则

### 先分层，再限额

不要一开始就给每个服务写一堆限制。先把服务按业务性质放进清晰的 slice：

- 关键业务服务
- 普通业务服务
- 后台批处理任务
- 监控与日志组件
- 用户登录会话
- 容器或虚拟机

分层清楚后，再逐步设置资源策略。

### 优先权重，谨慎硬限制

对关键服务，优先使用：

- `CPUWeight=`
- `IOWeight=`
- `MemoryLow=` 或适度 `MemoryHigh=`

对低优先级任务，可以使用：

- `CPUQuota=`
- `MemoryMax=`
- `IOReadBandwidthMax=`
- `IOWriteBandwidthMax=`
- `TasksMax=`

硬限制应服务于隔离和保护，不应成为性能调优的第一选择。

### 先观察，再收紧

建议流程：

1. 只设置 slice，不设置硬限制。
2. 开启 accounting 并观察资源峰值。
3. 设置权重和高水位。
4. 压测或观察一个业务周期。
5. 最后设置硬上限。

### 父级限制要留余量

父 slice 是总资源池。父级限制过紧会让多个子服务互相影响。建议父级限制保守一些，子服务再分别设置更具体的边界。

## 推荐 slice 模型

```text
-.slice
├── system.slice
├── user.slice
├── machine.slice
├── critical.slice
├── apps.slice
│   ├── apps-web.slice
│   ├── apps-worker.slice
│   └── apps-cron.slice
├── batch.slice
├── observability.slice
└── sandbox.slice
```

| slice | 放置内容 | 策略 |
|-------|----------|------|
| `critical.slice` | 支付、认证、核心 API、核心数据库代理 | 高权重、谨慎硬限制 |
| `apps.slice` | 普通业务服务 | 中高权重、适度内存边界 |
| `apps-web.slice` | Web/API 服务 | 高 CPU/IO 权重，避免过低 CPUQuota |
| `apps-worker.slice` | Worker、消费者 | 按队列重要性设置 quota 和内存 |
| `apps-cron.slice` | 应用定时任务 | 限制 CPU、IO、内存峰值 |
| `batch.slice` | 备份、压缩、构建、导入导出 | 低权重、明确硬限制 |
| `observability.slice` | Prometheus、日志 agent、node_exporter | 保证可用，不要限制过死 |
| `sandbox.slice` | 实验任务、临时命令 | 严格限制 |

## 基础 slice 模板

### critical.slice

`/etc/systemd/system/critical.slice`

```ini
[Unit]
Description=Critical Business Services Slice
Documentation=man:systemd.resource-control(5)

[Slice]
CPUWeight=1000
IOWeight=1000
MemoryHigh=24G
TasksMax=30000
```

说明：

- 不直接设置 `CPUQuota`，避免给关键业务人为封顶。
- `MemoryHigh` 用于提示和回收，不直接杀服务。
- 是否设置 `MemoryMax` 取决于服务器内存和服务特性。

### apps.slice

`/etc/systemd/system/apps.slice`

```ini
[Unit]
Description=Application Services Slice
Documentation=man:systemd.resource-control(5)

[Slice]
CPUWeight=300
IOWeight=300
MemoryHigh=16G
MemoryMax=24G
TasksMax=40000
```

说明：

- 适合普通业务服务池。
- 父级 `MemoryMax` 应明显高于单服务峰值总和中的合理上限。

### batch.slice

`/etc/systemd/system/batch.slice`

```ini
[Unit]
Description=Batch and Maintenance Jobs Slice
Documentation=man:systemd.resource-control(5)

[Slice]
CPUWeight=50
CPUQuota=200%
IOWeight=50
MemoryHigh=4G
MemoryMax=8G
TasksMax=10000
```

说明：

- 整个批处理池最多使用约 2 个 CPU 核。
- 有 IO 竞争时优先级低。
- 适合备份、压缩、离线任务。

### observability.slice

`/etc/systemd/system/observability.slice`

```ini
[Unit]
Description=Observability Services Slice
Documentation=man:systemd.resource-control(5)

[Slice]
CPUWeight=200
IOWeight=200
MemoryHigh=4G
MemoryMax=6G
TasksMax=8000
```

说明：

- 监控日志组件不能被压得太死。
- 故障时如果监控组件先死，会失去关键证据。

### sandbox.slice

`/etc/systemd/system/sandbox.slice`

```ini
[Unit]
Description=Sandbox and Temporary Tasks Slice
Documentation=man:systemd.resource-control(5)

[Slice]
CPUWeight=20
CPUQuota=100%
IOWeight=20
MemoryHigh=1G
MemoryMax=2G
TasksMax=1024
```

说明：适合临时实验、手工跑脚本、一次性分析任务。

## 服务 drop-in 模板

### Web/API 服务

```ini
[Service]
Slice=apps-web.slice
CPUWeight=500
IOWeight=500
MemoryHigh=2G
MemoryMax=3G
TasksMax=4096
OOMPolicy=stop
```

### Worker 服务

```ini
[Service]
Slice=apps-worker.slice
CPUWeight=200
CPUQuota=200%
IOWeight=200
MemoryHigh=4G
MemoryMax=6G
TasksMax=8192
OOMPolicy=stop
```

### 定时任务服务

```ini
[Service]
Slice=apps-cron.slice
CPUWeight=80
CPUQuota=100%
IOWeight=80
MemoryHigh=1G
MemoryMax=2G
TasksMax=2048
```

### 备份服务

```ini
[Service]
Slice=batch.slice
CPUWeight=30
CPUQuota=50%
IOWeight=30
MemoryMax=1G
TasksMax=1024
```

如需限制具体磁盘带宽：

```ini
[Service]
IOReadBandwidthMax=/dev/nvme0n1 100M
IOWriteBandwidthMax=/dev/nvme0n1 50M
```

## 临时命令模板

### 受限 shell

```shell
systemd-run --scope --slice=sandbox.slice -p MemoryMax=1G -p CPUQuota=50% bash
```

### 受限编译任务

```shell
systemd-run --scope --slice=batch.slice -p CPUQuota=200% -p MemoryMax=4G make -j8
```

### 受限数据导入

```shell
systemd-run --unit=data-import --slice=batch.slice -p CPUQuota=100% -p MemoryMax=3G /usr/local/bin/import-data
```

查看临时任务：

```shell
systemctl status data-import.service
systemctl show data-import.service -p ControlGroup -p MemoryCurrent -p CPUUsageNSec
```

## 生产变更流程

### 变更前

记录当前状态：

```shell
systemctl cat example.service
systemctl show example.service -p Slice -p ControlGroup -p CPUWeight -p CPUQuotaPerSecUSec -p MemoryCurrent -p MemoryPeak -p MemoryHigh -p MemoryMax -p IOWeight -p TasksCurrent -p TasksMax
journalctl -u example.service -b --no-pager
```

确认：

- 服务峰值内存是多少。
- 服务是否多线程或多进程。
- 服务是否延迟敏感。
- 服务是否能承受重启。
- 父 slice 是否已有总限制。

### 变更中

```shell
systemctl edit example.service
systemctl daemon-reload
systemctl restart example.service
```

如果只是修改部分资源限制，有些属性可以通过 `systemctl set-property` 临时设置：

```shell
systemctl set-property example.service CPUWeight=300 MemoryHigh=2G
```

注意：`set-property` 默认可能写入持久 drop-in，具体行为取决于 systemd 版本和参数。生产使用前先在测试机验证。

### 变更后

```shell
systemctl show example.service -p Slice -p ControlGroup -p CPUWeight -p CPUQuotaPerSecUSec -p MemoryHigh -p MemoryMax -p IOWeight -p TasksCurrent -p TasksMax
systemd-cgls example.service
systemd-cgtop
journalctl -u example.service -b --no-pager
```

观察：

- `memory.events` 是否出现 `high`、`oom`、`oom_kill` 增长。
- `cpu.stat` 是否出现明显 throttling。
- 服务延迟、错误率、吞吐是否异常。
- 重启次数是否增加。

## 回滚方式

查看 drop-in：

```shell
systemctl cat example.service
systemctl show example.service -p DropInPaths
```

删除对应 drop-in 文件后：

```shell
systemctl daemon-reload
systemctl restart example.service
```

如果通过 `systemctl set-property` 写入了 drop-in，通常位于：

```text
/etc/systemd/system.control/
/run/systemd/system.control/
/etc/systemd/system/<unit>.d/
```

具体以 `systemctl show <unit> -p DropInPaths` 为准。

## 不同服务的建议

### 数据库

建议：

- 谨慎设置 `MemoryMax`，优先结合数据库自身内存参数。
- 不要随意设置低 `CPUQuota`。
- 可以设置较高 `IOWeight`。
- 对延迟敏感数据库，谨慎使用 swap。

风险：数据库通常有自己的 buffer pool、cache、后台线程和 IO 调度策略。cgroup 限制应与数据库配置一起设计。

### Web/API

建议：

- 使用较高 `CPUWeight` 和 `IOWeight`。
- 设置合理 `MemoryHigh`，再根据压测结果设置 `MemoryMax`。
- `TasksMax` 应高于最大连接数、worker 数和线程池峰值。

### Worker/消费者

建议：

- 可以用 `CPUQuota` 控制整体消费速度。
- 根据队列优先级分不同 slice。
- 使用 `MemoryMax` 防止异常消息导致内存爆炸。

### 备份/压缩/构建

建议：

- 放入 `batch.slice`。
- 设置低 `CPUWeight` 和 `IOWeight`。
- 需要时设置磁盘带宽上限。
- 避免在业务高峰运行。

### 监控/日志

建议：

- 放入 `observability.slice`。
- 不要把 `MemoryMax` 设置太低。
- 保留足够 IO 能力，避免故障时日志堆积。

## 容器与 systemd slice

Docker、containerd、Kubernetes 也使用 cgroup。使用 systemd 作为 cgroup driver 时，容器通常会出现在 systemd 管理的 cgroup 层级下。

注意事项：

- 不要同时让多个管理器争抢同一个 cgroup 子树。
- Kubernetes 节点上要理解 kubelet 的 cgroup driver 和 systemd 的关系。
- 容器资源限制通常应由容器编排系统管理，而不是手工改容器 cgroup 文件。
- 可以通过上层 slice 限制某类容器运行时的总资源，但要先确认层级和委托关系。

常见检查：

```shell
systemd-cgls machine.slice
systemctl show docker.service -p Slice -p ControlGroup
systemctl show containerd.service -p Slice -p ControlGroup
```

## 监控指标建议

生产环境建议长期采集：

| 类别 | 指标 |
|------|------|
| CPU | 使用率、throttling 次数、throttled 时间、load、PSI |
| 内存 | current、peak、high events、oom、oom_kill、swap |
| IO | 读写字节、IOPS、延迟、队列长度、限速命中 |
| PID | current、max、fork 失败 |
| systemd | unit 状态、重启次数、失败原因 |
| 业务 | 延迟、错误率、吞吐、队列积压 |

如果内核支持 PSI，可以查看：

```shell
cat /proc/pressure/cpu
cat /proc/pressure/memory
cat /proc/pressure/io
```

PSI 能帮助判断进程因为 CPU、内存、IO 压力而等待的时间比例。

## 最小可用落地方案

如果你只想先把服务器管起来，可以按下面最小方案执行：

1. 创建 `apps.slice`、`batch.slice`、`observability.slice`。
2. 把核心业务服务放入 `apps.slice` 或 `critical.slice`。
3. 把备份、构建、导入导出放入 `batch.slice`。
4. 给 `batch.slice` 设置 `CPUQuota=200%`、`IOWeight=50`、`MemoryMax=8G`。
5. 给业务服务先设置 `CPUWeight` 和 `MemoryHigh`，暂不设置激进硬限制。
6. 用 `systemd-cgtop`、`memory.events`、`cpu.stat` 观察一周。
7. 根据峰值和业务 SLA 再收紧 `MemoryMax`、`TasksMax`、IO 限速。

## 检查脚本思路

不依赖脚本也可以手工检查。核心命令是：

```shell
systemctl show <unit> -p Slice -p ControlGroup
systemctl cat <unit>
systemd-cgls <unit>
systemd-cgtop
cat /sys/fs/cgroup/<path>/cpu.stat
cat /sys/fs/cgroup/<path>/memory.events
cat /sys/fs/cgroup/<path>/io.stat
cat /sys/fs/cgroup/<path>/pids.current
```

建议把这些命令加入自己的运维 runbook，并结合监控系统长期留存。

## 总结

生产中使用 cgroup 和 systemd slice 的关键不是“限制越多越好”，而是建立清晰的资源层级、保护关键服务、约束低优先级任务，并且能够在故障时快速解释资源行为。

推荐默认策略：

- 关键服务：高权重、少硬限、强监控。
- 普通服务：适度高水位和进程数限制。
- 后台任务：低权重、明确 CPU/IO/内存上限。
- 监控日志：保证可用，避免过度限制。
- 临时任务：统一放入 sandbox 或 batch slice。
